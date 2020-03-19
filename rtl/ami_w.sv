//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: AXI MASTER INTERFACE.WRITE. 


module ami_w // ami_w: Axi Master Interface Write
#(
   //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 40                  , // AXI ADDRESS BUS WIDTH
    AXI_IW     = 8                   , // AXI ID TAG  BITS WIDTH
    AXI_LW     = 8                   , // AXI AWLEN   BITS WIDTH
    AXI_SW     = 3                   , // AXI AWSIZE  BITS WIDTH
    AXI_BURSTW = 2                   , // AXI AWBURST BITS WIDTH
    AXI_BRESPW = 2                   , // AXI BRESP   BITS WIDTH
    AXI_RRESPW = 2                   , // AXI RRESP   BITS WIDTH
    //--------- AMI CONFIGURE --------
    AMI_OD     = 4                   , // AMI OUTSTANDING DEPTH
    AMI_AD     = 4                   , // AMI AW/AR CHANNEL BUFFER DEPTH
    AMI_RD     = 64                  , // AMI R CHANNEL BUFFER DEPTH
    AMI_WD     = 64                  , // AMI W CHANNEL BUFFER DEPTH
    AMI_BD     = 4                   , // AMI B CHANNEL BUFFER DEPTH
    //-------- DERIVED PARAMETERS ----
    AXI_BYTES  = AXI_DW/8            , // BYTES NUMBER IN <AXI_DW>
    AXI_WSTRBW = AXI_BYTES           , // AXI WSTRB BITS WIDTH
    AXI_BYTESW = $clog2(AXI_BYTES+1)   
)(
    //---- AXI GLOBAL ---------------------------
    input  logic                    ACLK        ,
    input  logic                    ARESETn     ,
    //---- AXI AW -------------------------------
    output logic [AXI_IW-1     : 0] AWID        ,
    output logic [AXI_AW-1     : 0] AWADDR      ,
    output logic [AXI_LW-1     : 0] AWLEN       ,
    output logic [AXI_SW-1     : 0] AWSIZE      ,
    output logic [AXI_BURSTW-1 : 0] AWBURST     ,
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
    input  logic [AXI_BRESPW-1 : 0] BRESP       ,
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
    input  logic [AXI_BURSTW-1 : 0] usr_awburst ,
    input  logic                    usr_awvalid ,
    output logic                    usr_awready ,
    //---- USER W  ------------------------------
    input  logic [AXI_DW-1     : 0] usr_wdata   ,
    input  logic [AXI_WSTRBW-1 : 0] usr_wstrb   ,
    input  logic                    usr_wlast   ,
    input  logic                    usr_wvalid  ,
    output logic                    usr_wready  ,
    //---- USER B  ------------------------------
    output logic [AXI_IW-1     : 0] usr_bid     ,
    output logic [AXI_BRESPW-1 : 0] usr_bresp   ,
    output logic                    usr_bvalid  ,
    input  logic                    usr_bready   
);

timeunit 1ns;
timeprecision 1ps;

localparam AFF_DW = AXI_IW + AXI_AW + AXI_LW + AXI_SW + AXI_BURSTW, // aw_buffer DW
           WFF_DW = AXI_DW + AXI_WSTRBW + 1,                        //  w_buffer DW(+1~wlast)
           BFF_DW = AXI_IW + AXI_BRESPW,                            //  b_buffer DW
           AFF_AW = $clog2(AMI_AD), // aw_buffer AW
           WFF_AW = $clog2(AMI_WD), //  w_buffer AW
           BFF_AW = $clog2(AMI_BD), //  b_buffer AW
           OUT_AW = $clog2(AMI_OD+1); // outstanding bits width

//--- outstanding counters ------------
logic [OUT_AW-1     : 0] out_cntaw    ; // for AW channel
logic [OUT_AW-1     : 0] out_cntw     ; // for W  channel

//--- aw fifo signals -----------------
logic                    aff_wreset_n ;
logic                    aff_rreset_n ;
logic                    aff_wclk     ;
logic                    aff_rclk     ;
logic                    aff_we       ;
logic                    aff_re       ;
logic                    aff_wfull    ;
logic                    aff_wafull   ;
logic                    aff_rempty   ;
logic [AFF_AW       : 0] aff_wcnt     ;
logic [AFF_DW-1     : 0] aff_d        ;
logic [AFF_DW-1     : 0] aff_q        ;
logic [AXI_IW-1     : 0] aq_id        ;
logic [AXI_AW-1     : 0] aq_addr      ;
logic [AXI_LW-1     : 0] aq_len       ;
logic [AXI_SW-1     : 0] aq_size      ;
logic [AXI_BURSTW-1 : 0] aq_burst     ;

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
logic [WFF_DW-1     : 0] wff_d        ;
logic [WFF_DW-1     : 0] wff_q        ;
logic [AXI_DW-1     : 0] wq_data      ;
logic [AXI_WSTRBW-1 : 0] wq_strb      ;
logic                    wq_last      ;

//--- bff_q disassemblies -------------
logic                    bff_wreset_n ;
logic                    bff_rreset_n ;
logic                    bff_wclk     ;
logic                    bff_rclk     ;
logic                    bff_we       ;
logic                    bff_re       ;
logic                    bff_wfull    ;
logic                    bff_wafull   ;
logic                    bff_rempty   ;
logic [BFF_AW       : 0] bff_wcnt     ;
logic [BFF_DW-1     : 0] bff_d        ;
logic [BFF_DW-1     : 0] bff_q        ;
logic [AXI_IW-1     : 0] bq_bid       ;
logic [AXI_BRESPW-1 : 0] bq_bresp     ;

// top ports 
assign AWID               = aq_id            ; 
assign AWADDR             = aq_addr          ;
assign AWLEN              = aq_len           ;
assign AWSIZE             = aq_size          ;
assign AWBURST            = aq_burst         ;
assign AWVALID            = !aff_rempty && out_cntaw<AMI_OD;
assign WDATA              = wq_data          ;
assign WSTRB              = wq_strb          ;
assign WLAST              = wq_last          ;
assign WVALID             = !wff_rempty && out_cntw<AMI_OD;
assign BREADY             = !bff_wfull       ;
assign usr_awready        = !aff_wfull       ;
assign usr_wready         = !wff_wfull       ;
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
    .wafull   ( aff_wafull   ), 
    .rempty   ( aff_rempty   ),
    .wcnt     ( aff_wcnt     ),
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
    .wafull   ( wff_wafull   ), 
    .rempty   ( wff_rempty   ),
    .wcnt     ( wff_wcnt     ),
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
    .wafull   ( bff_wafull   ), 
    .rempty   ( bff_rempty   ),
    .wcnt     ( bff_wcnt     ),
    .d        ( bff_d        ),
    .q        ( bff_q        ) 
);

always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn)
        out_cntaw <= '0;
    else if(aff_re || BVALID & BREADY)
        out_cntaw <= out_cntaw + aff_re - (BVALID & BREADY);

always_ff @(posedge ACLK or negedge ARESETn)
    if(!ARESETn)
        out_cntw <= '0;
    else if(wff_re & wq_last || BVALID & BREADY)
        out_cntw <= out_cntw + wq_last - (BVALID & BREADY);

endmodule
