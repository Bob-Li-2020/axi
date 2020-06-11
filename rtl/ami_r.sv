//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: AXI MASTER INTERFACE.READ. This module includes:
//--              1. usr_clk/ACLK clock domain cross;
//--              2. AXI outstanding control;
//--              3. AR/R channel alignment(AR channel precedes R channel).

module ami_r // ami_r: Axi Master Interface Read
#(
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 32                  , // AXI ADDRESS BUS WIDTH(MUST >= 32)
    AXI_IW     = 8                   , // AXI ID TAG  BITS WIDTH
    AXI_LW     = 8                   , // AXI AWLEN   BITS WIDTH
    AXI_SW     = 3                   , // AXI AWSIZE  BITS WIDTH
    //--------- AMI CONFIGURE --------
    AMI_OD     = 4                   , // AMI OUTSTANDING DEPTH
    AMI_AD     = 8                   , // AMI AW/AR CHANNEL FIFO DEPTH
    AMI_XD     = 16                  , // AMI W/R   CHANNEL FIFO DEPTH
    AMI_BD     = 8                   , // AMI B     CHANNEL FIFO DEPTH
    RAM_WS     = 9                   , // RAM read wait states
    //-------- DERIVED PARAMETERS ----
    AXI_WSTRBW = AXI_DW/8              // AXI WSTRB BITS WIDTH
)(
    //---- AXI GLOBAL -----------------------
    input  logic                ACLK        ,
    input  logic                ARESETn     ,
    //---- AXI AR ---------------------------
    output logic [AXI_IW-1 : 0] ARID        ,
    output logic [AXI_AW-1 : 0] ARADDR      ,
    output logic [AXI_LW-1 : 0] ARLEN       ,
    output logic [AXI_SW-1 : 0] ARSIZE      ,
    output logic [1        : 0] ARBURST     ,
    output logic                ARVALID     ,
    input  logic                ARREADY     ,
    //---- AXI R ----------------------------
    input  logic [AXI_IW-1 : 0] RID         ,
    input  logic [AXI_DW-1 : 0] RDATA       ,
    input  logic [1        : 0] RRESP       ,
    input  logic                RLAST       ,
    input  logic                RVALID      ,
    output logic                RREADY      ,
    //---- USER GLOBAL ----------------------
    input  logic                usr_clk     ,
    input  logic                usr_reset_n ,
    //---- USER AR --------------------------
    input  logic [AXI_IW-1 : 0] usr_arid    ,
    input  logic [AXI_AW-1 : 0] usr_araddr  ,
    input  logic [AXI_LW-1 : 0] usr_arlen   ,
    input  logic [AXI_SW-1 : 0] usr_arsize  ,
    input  logic [1        : 0] usr_arburst ,
    input  logic                usr_arvalid ,
    output logic                usr_arready ,
    //---- USER R  --------------------------
    output logic [AXI_IW-1 : 0] usr_rid     ,
    output logic [AXI_DW-1 : 0] usr_rdata   ,
    output logic [1        : 0] usr_rresp   ,
    output logic                usr_rlast   ,
    output logic                usr_rvalid  ,
    input  logic                usr_rready   
);

timeunit 1ns;
timeprecision 1ps;

localparam AFF_DW = AXI_IW + AXI_AW + AXI_LW + AXI_SW + 2, // ar_buffer DW(+2~AXBURST)
           RFF_DW = AXI_IW + AXI_DW + 2 + 1,               //  r_buffer DW(+2~RRESP; +1~wlast)
           AFF_AW = $clog2(AMI_AD),   // ar_buffer AW
           RFF_AW = $clog2(AMI_XD),   //  r_buffer AW
           OUT_AW = $clog2(AMI_OD+1); // outstanding bits width

logic [OUT_AW-1 : 0] ost_cc       ; // outstanding counter

//--- ar fifo signals -------------
logic                aff_wreset_n ;
logic                aff_rreset_n ;
logic                aff_wclk     ;
logic                aff_rclk     ;
logic                aff_we       ;
logic                aff_re       ;
logic                aff_wfull    ;
logic                aff_rempty   ;
logic [AFF_AW   : 0] aff_wcnt     ;
logic [AFF_AW   : 0] aff_rcnt     ;
logic [AFF_DW-1 : 0] aff_d        ;
logic [AFF_DW-1 : 0] aff_q        ;
logic [AXI_IW-1 : 0] aq_id        ;
logic [AXI_AW-1 : 0] aq_addr      ;
logic [AXI_LW-1 : 0] aq_len       ;
logic [AXI_SW-1 : 0] aq_size      ;
logic [1        : 0] aq_burst     ;

//---  r fifo signals -------------
logic                rff_wreset_n ;
logic                rff_rreset_n ;
logic                rff_wclk     ;
logic                rff_rclk     ;
logic                rff_we       ;
logic                rff_re       ;
logic                rff_wfull    ;
logic                rff_rempty   ;
logic [RFF_AW   : 0] rff_wcnt     ;
logic [RFF_AW   : 0] rff_rcnt     ;
logic [RFF_DW-1 : 0] rff_d        ;
logic [RFF_DW-1 : 0] rff_q        ;
logic [AXI_IW-1 : 0] rq_id        ;
logic [AXI_DW-1 : 0] rq_data      ;
logic [1        : 0] rq_resp      ;
logic                rq_last      ;

// top ports
assign ARID         = aq_id            ;
assign ARADDR       = aq_addr          ;
assign ARLEN        = aq_len           ;
assign ARSIZE       = aq_size          ;
assign ARBURST      = aq_burst         ;
assign ARVALID      = !aff_rempty && ost_cc<AMI_OD;
assign RREADY       = !rff_wfull       ;
assign usr_arready  = !aff_wfull       ;
assign usr_rid      = rq_id            ;
assign usr_rdata    = rq_data          ;
assign usr_rresp    = rq_resp          ;
assign usr_rlast    = rq_last          ;
assign usr_rvalid   = !rff_rempty      ;

// ar fifo 
assign aff_wreset_n = usr_reset_n      ; 
assign aff_rreset_n = ARESETn          ;
assign aff_wclk     = usr_clk          ;
assign aff_rclk     = ACLK             ;
assign aff_we       = usr_arvalid & usr_arready;         
assign aff_re       = ARVALID & ARREADY;
assign aff_d        = {usr_arid, usr_araddr, usr_arlen, usr_arsize, usr_arburst};
assign {aq_id, aq_addr, aq_len, aq_size, aq_burst} = aff_q;

// r fifo
assign rff_wreset_n = ARESETn          ; 
assign rff_rreset_n = usr_reset_n      ;
assign rff_wclk     = ACLK             ;
assign rff_rclk     = usr_clk          ;
assign rff_we       = RVALID & RREADY  ;
assign rff_re       = usr_rvalid & usr_rready;
assign rff_d        = {RID, RDATA, RRESP, RLAST};
assign {rq_id, rq_data, rq_resp, rq_last} = rff_q;

//--- fifo instances ---------
afifo #(
    .AW ( AFF_AW ),
    .DW ( AFF_DW )
) ar_buffer (
    .wreset_n ( aff_wreset_n ),
    .rreset_n ( aff_rreset_n ),
    .wclk     ( aff_wclk     ),
    .rclk     ( aff_rclk     ),
    .we       ( aff_we       ),
    .re       ( aff_re       ),
    .wfull    ( aff_wfull    ),
    .rempty   ( aff_rempty   ),
    .wcnt     ( aff_wcnt     ),
    .rcnt     ( aff_rcnt     ),
    .d        ( aff_d        ),
    .q        ( aff_q        ) 
);

afifo #(
    .AW ( RFF_AW ),
    .DW ( RFF_DW )
) r_buffer (
    .wreset_n ( rff_wreset_n ),
    .rreset_n ( rff_rreset_n ),
    .wclk     ( rff_wclk     ),
    .rclk     ( rff_rclk     ),
    .we       ( rff_we       ),
    .re       ( rff_re       ),
    .wfull    ( rff_wfull    ),
    .rempty   ( rff_rempty   ),
    .wcnt     ( rff_wcnt     ),
    .rcnt     ( rff_rcnt     ),
    .d        ( rff_d        ),
    .q        ( rff_q        ) 
);

always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn)
        ost_cc <= '0;
    else if(aff_re || RLAST & RREADY & RVALID)
        ost_cc <= ost_cc+aff_re-(RLAST & RREADY & RVALID);

endmodule
