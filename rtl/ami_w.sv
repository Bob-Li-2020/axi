//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: AXI MASTER INTERFACE.WRITE. This module includes:
//--              1. usr_clk/ACLK clock domain cross;
//--              2. AXI outstanding control;
//--              3. AW/W channel alignment(AW channel precedes W channel).

module ami_w // ami_w: Axi Master Interface Write
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
    //---- AXI GLOBAL ---------------------------
    input  logic                    ACLK        ,
    input  logic                    ARESETn     ,
    //---- AXI AW -------------------------------
    output logic [AXI_IW-1     : 0] AWID        ,
    output logic [AXI_AW-1     : 0] AWADDR      ,
    output logic [AXI_LW-1     : 0] AWLEN       ,
    output logic [AXI_SW-1     : 0] AWSIZE      ,
    output logic [1            : 0] AWBURST     ,
    output logic                    AWVALID     ,
    input  logic                    AWREADY     ,
    //---- AXI W --------------------------------
    output logic [AXI_DW-1     : 0] WDATA       ,
    output logic [AXI_WSTRBW-1 : 0] WSTRB       ,
    output logic                    WLAST       ,
    output logic                    WVALID      ,
    input  logic                    WREADY      ,
    //---- AXI B --------------------------------
    input  logic [AXI_IW-1     : 0] BID         ,
    input  logic [1            : 0] BRESP       ,
    input  logic                    BVALID      ,
    output logic                    BREADY      ,
    //---- USER GLOBAL --------------------------
    input  logic                    usr_clk     ,
    input  logic                    usr_reset_n ,
    //---- USER AW ------------------------------
    input  logic [AXI_IW-1     : 0] usr_awid    ,
    input  logic [AXI_AW-1     : 0] usr_awaddr  ,
    input  logic [AXI_LW-1     : 0] usr_awlen   ,
    input  logic [AXI_SW-1     : 0] usr_awsize  ,
    input  logic [1            : 0] usr_awburst ,
    input  logic                    usr_awvalid ,
    output logic                    usr_awready ,
    //---- USER W  ------------------------------
    input  logic [AXI_DW-1     : 0] usr_wdata   ,
    input  logic [AXI_WSTRBW-1 : 0] usr_wstrb   ,
    input  logic                    usr_wlast   ,
    input  logic                    usr_wvalid  ,
    output logic                    usr_wready  ,
    output logic                    usr_wnafull , // !almost_full
    //---- USER B  ------------------------------
    output logic [AXI_IW-1     : 0] usr_bid     ,
    output logic [1            : 0] usr_bresp   ,
    output logic                    usr_bvalid  ,
    input  logic                    usr_bready   
);

timeunit 1ns;
timeprecision 1ps;

localparam AFF_DW = AXI_IW + AXI_AW + AXI_LW + AXI_SW + 2, // aw_buffer DW(+2~AXBURST)
           WFF_DW = AXI_DW + AXI_WSTRBW + 1,               //  w_buffer DW(+1~wlast)
           BFF_DW = AXI_IW + 2,                            //  b_buffer DW(+2~BRESP)
           LFF_DW = AXI_LW,
           AFF_AW = $clog2(AMI_AD), // aw_buffer AW
           WFF_AW = $clog2(AMI_XD), //  w_buffer AW
           BFF_AW = $clog2(AMI_BD), //  b_buffer AW
           LFF_AW = AFF_AW,
           OUT_AW = $clog2(AMI_OD+1); // outstanding bits width

logic [OUT_AW-1     : 0] ost_cc       ; // outstanding counter
logic [OUT_AW-1     : 0] ost_cc2      ; // outstanding counter as of "wlast"

//--- aw fifo signals -----------------
logic                    aff_wreset_n ;
logic                    aff_rreset_n ;
logic                    aff_wclk     ;
logic                    aff_rclk     ;
logic                    aff_we       ;
logic                    aff_re       ;
logic                    aff_wfull    ;
logic                    aff_rempty   ;
logic [AFF_AW       : 0] aff_wcnt     ;
logic [AFF_AW       : 0] aff_rcnt     ;
logic [AFF_DW-1     : 0] aff_d        ;
logic [AFF_DW-1     : 0] aff_q        ;
logic [AXI_IW-1     : 0] aq_id        ;
logic [AXI_AW-1     : 0] aq_addr      ;
logic [AXI_LW-1     : 0] aq_len       ;
logic [AXI_SW-1     : 0] aq_size      ;
logic [1            : 0] aq_burst     ;

//---  w fifo signals -----------------
logic                    wff_wreset_n ;
logic                    wff_rreset_n ;
logic                    wff_wclk     ;
logic                    wff_rclk     ;
logic                    wff_we       ;
logic                    wff_re       ;
logic                    wff_wfull    ;
logic                    wff_wafull   ;
logic                    wff_rempty   ;
logic [WFF_AW       : 0] wff_wcnt     ;
logic [WFF_AW       : 0] wff_rcnt     ;
logic [WFF_DW-1     : 0] wff_d        ;
logic [WFF_DW-1     : 0] wff_q        ;
logic [AXI_DW-1     : 0] wq_data      ;
logic [AXI_WSTRBW-1 : 0] wq_strb      ;
logic                    wq_last      ;

//---  b fifo signals -----------------
logic                    bff_wreset_n ;
logic                    bff_rreset_n ;
logic                    bff_wclk     ;
logic                    bff_rclk     ;
logic                    bff_we       ;
logic                    bff_re       ;
logic                    bff_wfull    ;
logic                    bff_rempty   ;
logic [BFF_AW       : 0] bff_wcnt     ;
logic [BFF_AW       : 0] bff_rcnt     ;
logic [BFF_DW-1     : 0] bff_d        ;
logic [BFF_DW-1     : 0] bff_q        ;
logic [AXI_IW-1     : 0] bq_bid       ;
logic [1            : 0] bq_bresp     ;

//---  awlen fifo signals -------------
logic                    lff_wreset_n ;
logic                    lff_rreset_n ;
logic                    lff_wclk     ;
logic                    lff_rclk     ;
logic                    lff_we       ;
logic                    lff_re       ;
logic                    lff_wfull    ;
logic                    lff_rempty   ;
logic [LFF_AW       : 0] lff_wcnt     ;
logic [LFF_AW       : 0] lff_rcnt     ;
logic [LFF_DW-1     : 0] lff_d        ;
logic [LFF_DW-1     : 0] lff_q        ;
logic [LFF_DW-1     : 0] lff_q_latch  ;

logic                    bursting     ;
logic [AXI_LW-1     : 0] burst_cc     ;

// top ports 
assign AWID               = aq_id            ; 
assign AWADDR             = aq_addr          ;
assign AWLEN              = aq_len           ;
assign AWSIZE             = aq_size          ;
assign AWBURST            = aq_burst         ;
assign AWVALID            = !aff_rempty && ost_cc<AMI_OD;
assign WDATA              = wq_data          ;
assign WSTRB              = wq_strb          ;
assign WLAST              = wff_re && burst_cc==lff_q_latch;
assign WVALID             = !wff_rempty && ost_cc2>0 && bursting;
assign BREADY             = !bff_wfull       ;
assign usr_awready        = !aff_wfull & !lff_wfull;
assign usr_wready         = !wff_wfull       ;
assign usr_wnafull        = !wff_wafull      ;
assign usr_bid            = bq_bid           ;
assign usr_bresp          = bq_bresp         ;
assign usr_bvalid         = !bff_rempty      ;

// aw fifo 
assign aff_wreset_n       = usr_reset_n      ; 
assign aff_rreset_n       = ARESETn          ;
assign aff_wclk           = usr_clk          ;
assign aff_rclk           = ACLK             ;
assign aff_we             = usr_awvalid & usr_awready;         
assign aff_re             = AWVALID & AWREADY;
assign aff_d              = {usr_awid, usr_awaddr, usr_awlen, usr_awsize, usr_awburst};
assign {aq_id, aq_addr, aq_len, aq_size, aq_burst} = aff_q;

// w fifo
assign wff_wreset_n       = usr_reset_n      ; 
assign wff_rreset_n       = ARESETn          ;
assign wff_wclk           = usr_clk          ;
assign wff_rclk           = ACLK             ;
assign wff_we             = usr_wvalid & usr_wready;
assign wff_re             = WVALID & WREADY  ;
assign wff_wafull         = (wff_wcnt+RAM_WS+2 >= AMI_XD) | wff_wfull;
assign wff_d              = {usr_wdata, usr_wstrb, usr_wlast};
assign {wq_data, wq_strb, wq_last} = wff_q   ;

// b fifo
assign bff_wreset_n       = ARESETn          ; 
assign bff_rreset_n       = usr_reset_n      ;
assign bff_wclk           = ACLK             ;
assign bff_rclk           = usr_clk          ;
assign bff_we             = BVALID & BREADY  ;
assign bff_re             = usr_bvalid & usr_bready;
assign bff_d              = {BID, BRESP}     ;
assign {bq_bid, bq_bresp} = bff_q            ;

// l fifo 
assign lff_wreset_n       = usr_reset_n      ;
assign lff_rreset_n       = ARESETn          ;
assign lff_wclk           = usr_clk          ;
assign lff_rclk           = ACLK             ;
assign lff_we             = aff_we           ;
assign lff_re             = !lff_rempty && (!bursting || WLAST);
assign lff_d              = usr_awlen        ;

// DMA CONTROL
always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn) begin
        lff_q_latch <= '0; // doesn't really matter
    end 
    else if(lff_re) begin
        lff_q_latch <= lff_q;
    end

always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn) begin
        bursting <= 1'b0;
        burst_cc <= '0;
    end
    else if(!bursting) begin
        bursting <= lff_re;
        burst_cc <= '0;
    end
    else begin
        bursting <= ~(WLAST & lff_rempty);
        burst_cc <= WLAST ? '0 : burst_cc+wff_re;
    end

//--- fifo instances ---------
afifo #(
    .AW ( AFF_AW ),
    .DW ( AFF_DW )
) aw_buffer (
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
    .AW ( WFF_AW ),
    .DW ( WFF_DW )
) w_buffer (
    .wreset_n ( wff_wreset_n ),
    .rreset_n ( wff_rreset_n ),
    .wclk     ( wff_wclk     ),
    .rclk     ( wff_rclk     ),
    .we       ( wff_we       ),
    .re       ( wff_re       ),
    .wfull    ( wff_wfull    ),
    .rempty   ( wff_rempty   ),
    .wcnt     ( wff_wcnt     ),
    .rcnt     ( wff_rcnt     ),
    .d        ( wff_d        ),
    .q        ( wff_q        ) 
);

afifo #(
    .AW ( BFF_AW ),
    .DW ( BFF_DW )
) b_buffer (
    .wreset_n ( bff_wreset_n ),
    .rreset_n ( bff_rreset_n ),
    .wclk     ( bff_wclk     ),
    .rclk     ( bff_rclk     ),
    .we       ( bff_we       ),
    .re       ( bff_re       ),
    .wfull    ( bff_wfull    ),
    .rempty   ( bff_rempty   ),
    .wcnt     ( bff_wcnt     ),
    .rcnt     ( bff_rcnt     ),
    .d        ( bff_d        ),
    .q        ( bff_q        ) 
);

afifo #(
    .AW ( LFF_AW ),
    .DW ( LFF_DW )
) len_buffer (
    .wreset_n ( lff_wreset_n ),
    .rreset_n ( lff_rreset_n ),
    .wclk     ( lff_wclk     ),
    .rclk     ( lff_rclk     ),
    .we       ( lff_we       ),
    .re       ( lff_re       ),
    .wfull    ( lff_wfull    ),
    .rempty   ( lff_rempty   ),
    .wcnt     ( lff_wcnt     ),
    .rcnt     ( lff_rcnt     ),
    .d        ( lff_d        ),
    .q        ( lff_q        ) 
);

always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn)
        ost_cc <= '0;
    else if(aff_re || BVALID & BREADY)
        ost_cc <= ost_cc+aff_re-(BVALID & BREADY);

always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn)
        ost_cc2 <= '0;
    else if(aff_re || WLAST)
        ost_cc2 <= ost_cc2+aff_re-WLAST;

endmodule
