//-- AUTHOR: LIBING
//-- DATE: 2019.12
//-- DESCRIPTION: AXI SLAVE INTERFACE.WRITE. BASED ON AXI4 SPEC.

// asi_w: Axi Slave Interface Write
module asi_w 
#(
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 32                  , // AXI ADDRESS BUS WIDTH
    AXI_IW     = 8                   , // AXI ID TAG  BITS WIDTH
    AXI_LW     = 8                   , // AXI AWLEN   BITS WIDTH
    AXI_SW     = 3                   , // AXI AWSIZE  BITS WIDTH
    AXI_BURSTW = 2                   , // AXI AWBURST BITS WIDTH
    AXI_BRESPW = 2                   , // AXI BRESP   BITS WIDTH
    AXI_RRESPW = 2                   , // AXI RRESP   BITS WIDTH
    //--------- ASI CONFIGURE --------
    ASI_AD     = 4                   , // ASI AW/AR CHANNEL BUFFER DEPTH
    ASI_RD     = 64                  , // ASI R CHANNEL BUFFER DEPTH
    ASI_WD     = 64                  , // ASI W CHANNEL BUFFER DEPTH
    ASI_BD     = 4                   , // ASI B CHANNEL BUFFER DEPTH
    ASI_ARB    = 0                   , // 1-GRANT READ WITH HIGHER PRIORITY; 0-GRANT WRITE WITH HIGHER PRIORITY
    //--------- SLAVE ATTRIBUTES -----
    SLV_WS     = 1                   , // SLAVE MODEL READ WAIT STATES CYCLE
    //-------- DERIVED PARAMETERS ----
    AXI_BYTES  = AXI_DW/8            , // BYTES NUMBER IN <AXI_DW>
    AXI_WSTRBW = AXI_BYTES           , // AXI WSTRB BITS WIDTH
    AXI_BYTESW = $clog2(AXI_BYTES+1)   
)(
    //---- AXI GLOBAL SIGNALS -----------------------
    input  logic                    ACLK            ,
    input  logic                    ARESETn         ,
    //---- AXI ADDRESS WRITE SIGNALS ----------------
    input  logic [AXI_IW-1     : 0] AWID            ,
    input  logic [AXI_AW-1     : 0] AWADDR          ,
    input  logic [AXI_LW-1     : 0] AWLEN           ,
    input  logic [AXI_SW-1     : 0] AWSIZE          ,
    input  logic [AXI_BURSTW-1 : 0] AWBURST         ,
    input  logic                    AWVALID         ,
    output logic                    AWREADY         ,
    //---- AXI DATA WRITE SIGNALS -------------------
    input  logic [AXI_DW-1     : 0] WDATA           ,
    input  logic [AXI_WSTRBW-1 : 0] WSTRB           ,
    input  logic                    WLAST           ,
    input  logic                    WVALID          ,
    output logic                    WREADY          ,
    //---- AXI WRITE RESPONSE SIGNALS ---------------
    output logic [AXI_IW-1     : 0] BID             ,
    output logic [AXI_BRESPW-1 : 0] BRESP           ,
    output logic                    BVALID          ,
    input  logic                    BREADY          ,
    //---- USER LOGIC SIGNALS -----------------------
    input  logic                    usr_clk         ,
    input  logic                    usr_reset_n     ,
    //AW CHANNEL
    output logic [AXI_IW-1     : 0] usr_wid         ,
    output logic [AXI_LW-1     : 0] usr_wlen        ,
    output logic [AXI_SW-1     : 0] usr_wsize       ,
    output logic [AXI_BURSTW-1 : 0] usr_wburst      ,
    //W CHANNEL
    output logic [AXI_AW-1     : 0] usr_waddr       ,
    output logic [AXI_DW-1     : 0] usr_wdata       ,
    output logic [AXI_WSTRBW-1 : 0] usr_wstrb       ,
    output logic                    usr_wlast       ,
    output logic                    usr_we          ,
    //ARBITER SIGNALS
    output logic                    usr_wrequest    , // arbiter write request
    input  logic                    usr_wgrant      , // arbiter write grant
    //ERROR FLAGS
    input  logic                    usr_wsize_error   // unsupported transfer size
);

timeunit 1ns;
timeprecision 1ps;

localparam AFF_DW = AXI_IW + AXI_AW + AXI_LW + AXI_SW + AXI_BURSTW,
           WFF_DW = AXI_DW + AXI_WSTRBW + 1,
           BFF_DW = AXI_IW + AXI_BRESPW,
           AFF_AW = $clog2(ASI_AD),
           WFF_AW = $clog2(ASI_WD),
           BFF_AW = $clog2(ASI_BD);

localparam [AXI_BURSTW-1 : 0] BT_FIXED     = 0;
localparam [AXI_BURSTW-1 : 0] BT_INCR      = 1;
localparam [AXI_BURSTW-1 : 0] BT_WRAP      = 2;
localparam [AXI_BURSTW-1 : 0] BT_RESERVED  = 3;

// BP_FIRST: transfer the first transfer
// BP_BURST: transfer the rest  transfer(s)
// BP_BRESP: waiting for sending write response 
// BP_IDLE : do nothing
enum logic [1:0] { BP_FIRST=2'b00, BP_BURST, BP_BRESP, BP_IDLE } st_cur, st_nxt; 

//------ easy signals ---------------------
wire                     clk              ;
wire                     rst_n            ;
wire                     aff_rvalid       ;
wire                     aff_rready       ;
wire                     bff_rvalid       ;

//------ aw fifo signals ------------------
logic                    aff_wreset_n     ;
logic                    aff_rreset_n     ;
logic                    aff_wclk         ;
logic                    aff_rclk         ;
logic                    aff_we           ;
logic                    aff_re           ;
logic                    aff_wfull        ;
logic                    aff_rempty       ;
logic [AFF_AW       : 0] aff_wcnt         ;
logic [AFF_AW       : 0] aff_rcnt         ;
logic [AFF_DW-1     : 0] aff_d            ;
logic [AFF_DW-1     : 0] aff_q            ;
logic [AXI_IW-1     : 0] aq_id            ;
logic [AXI_AW-1     : 0] aq_addr          ;
logic [AXI_LW-1     : 0] aq_len           ;
logic [AXI_SW-1     : 0] aq_size          ;
logic [AXI_BURSTW-1 : 0] aq_burst         ;
logic [AXI_IW-1     : 0] aq_id_latch      ;
logic [AXI_AW-1     : 0] aq_addr_latch    ;
logic [AXI_LW-1     : 0] aq_len_latch     ;
logic [AXI_SW-1     : 0] aq_size_latch    ;
logic [AXI_BURSTW-1 : 0] aq_burst_latch   ;

//------ w fifo signals -------------------
logic                    wff_wreset_n     ;
logic                    wff_rreset_n     ;
logic                    wff_wclk         ;
logic                    wff_rclk         ;
logic                    wff_we           ;
logic                    wff_re           ;
logic                    wff_wfull        ;
logic                    wff_rempty       ;
logic [WFF_AW       : 0] wff_wcnt         ;
logic [WFF_AW       : 0] wff_rcnt         ;
logic [WFF_DW-1     : 0] wff_d            ;
logic [WFF_DW-1     : 0] wff_q            ;
logic [AXI_DW-1     : 0] wq_data          ;
logic [AXI_WSTRBW-1 : 0] wq_strb          ;
logic                    wq_last          ;

//------ b fifo signals -------------------
logic                    bff_wreset_n     ;
logic                    bff_rreset_n     ;
logic                    bff_wclk         ;
logic                    bff_rclk         ;
logic                    bff_we           ;
logic                    bff_re           ;
logic                    bff_wfull        ;
logic                    bff_rempty       ;
logic [BFF_AW       : 0] bff_wcnt         ;
logic [BFF_AW       : 0] bff_rcnt         ;
logic [BFF_DW-1     : 0] bff_d            ;
logic [BFF_DW-1     : 0] bff_q            ;
logic [AXI_IW-1     : 0] bq_bid           ;
logic [AXI_BRESPW-1 : 0] bq_bresp         ;

//------ burst addresses ------------------
logic [AXI_BYTESW-1 : 0] burst_addr_inc   ;
logic [AXI_AW-0     : 0] burst_addr_nxt   ;
logic [AXI_AW-0     : 0] burst_addr_nxt_b ; // bounded to 4KB 
logic [AXI_AW-1     : 0] burst_addr       ;
logic [AXI_LW-1     : 0] burst_cc         ;
logic                    burst_last       ;
logic [AXI_AW-1     : 0] start_addr       ;
logic [AXI_AW-1     : 0] start_addr_mask  ;
logic [AXI_AW-1     : 0] aligned_addr     ;

//------ other signals --------------------
logic                    error_size       ;
logic                    error_w4KB       ;
logic [AXI_BRESPW-1 : 0] usr_bresp        ;

// output
assign AWREADY        = ~aff_wfull         ;
assign WREADY         = ~wff_wfull         ;
assign BID            = bq_bid             ;
assign BRESP          = bq_bresp           ;
assign BVALID         = bff_rvalid         ;
assign usr_wid        = st_cur==BP_FIRST ? aq_id    : aq_id_latch;      
assign usr_wlen       = st_cur==BP_FIRST ? aq_len   : aq_len_latch;    
assign usr_wsize      = st_cur==BP_FIRST ? aq_size  : aq_size_latch;  
assign usr_wburst     = st_cur==BP_FIRST ? aq_burst : aq_burst_latch;
assign usr_waddr      = st_cur==BP_FIRST ? start_addr : burst_addr;
assign usr_wdata      = wq_data            ;
assign usr_wstrb      = wff_re ? wq_strb : '0;
assign usr_wlast      = wff_re ? wq_last : '0; 
assign usr_we         = wff_re             ;
assign usr_wrequest   = aff_rcnt-aff_re>0  ;

// easy
assign clk            = usr_clk            ;
assign rst_n          = usr_reset_n        ;
assign aff_rvalid     = !aff_rempty        ; 
assign aff_rready     = !wff_rempty && st_cur==BP_FIRST && usr_wgrant;
assign bff_rvalid     = !bff_rempty        ;

// aw fifo
assign aff_wreset_n   = ARESETn            ;
assign aff_rreset_n   = usr_reset_n        ;
assign aff_wclk       = ACLK               ;
assign aff_rclk       = usr_clk            ;
assign aff_we         = AWVALID & AWREADY  ;
assign aff_re         = aff_rvalid & aff_rready; 
assign aff_d          = { AWID, AWADDR, AWLEN, AWSIZE, AWBURST };
assign { aq_id, aq_addr, aq_len, aq_size, aq_burst } = aff_q;

// w fifo
assign wff_wreset_n   = ARESETn            ;
assign wff_rreset_n   = usr_reset_n        ;
assign wff_wclk       = ACLK               ;
assign wff_rclk       = usr_clk            ;
assign wff_we         = WVALID & WREADY    ;
assign wff_re         = aff_re || st_cur==BP_BURST && !wff_rempty;
assign wff_d          = { WDATA, WSTRB, WLAST };
assign { wq_data, wq_strb, wq_last } = wff_q;

// b fifo
assign bff_wreset_n   = usr_reset_n        ;
assign bff_rreset_n   = ARESETn            ;
assign bff_wclk       = usr_clk            ;
assign bff_rclk       = ACLK               ;
assign bff_we         = !bff_wfull && (burst_last || st_cur==BP_BRESP);
assign bff_re         = bff_rvalid & BREADY;
assign bff_d          = {usr_wid, usr_bresp};
assign { bq_bid, bq_bresp } = bff_q        ;

// burst
assign burst_addr_inc = usr_wburst==BT_FIXED ? '0 : {{(AXI_BYTESW-1){1'b0}},1'b1}<<usr_wsize;
assign burst_addr_nxt = st_cur==BP_FIRST ? burst_addr_inc+{1'b0,aligned_addr} : st_cur==BP_BURST ? burst_addr_inc+{1'b0,burst_addr} : 'x; 
assign start_addr     = st_cur==BP_FIRST ? aq_addr : aq_addr_latch;
assign aligned_addr   = start_addr_mask & start_addr;
assign burst_last     = (wff_re && aq_len=='0 && st_cur==BP_FIRST) || (wff_re && burst_cc==aq_len_latch && st_cur==BP_BURST);

always_comb begin
    start_addr_mask = ('1)<<($clog2(AXI_BYTES));
	for(int i=0;i<=($clog2(AXI_BYTES));i++) begin
		if(i==usr_wsize) begin
            start_addr_mask = ('1)<<i;
		end
	end
end

// others
assign error_size = (usr_wsize > $clog2(AXI_BYTES)) | usr_wsize_error;
assign usr_bresp  = { error_size | error_w4KB, 1'b0 };

generate 
    if(AXI_AW>12) begin: ERROR_4KB
        assign burst_addr_nxt_b = burst_addr_nxt[12]==start_addr[12] ? burst_addr_nxt : (st_cur==BP_FIRST ? {1'b0,aligned_addr} : st_cur==BP_BURST ? {1'b0,burst_addr} : 'x);
        assign error_w4KB       = burst_addr_nxt[12]!=start_addr[12] && st_cur==BP_BURST && !burst_last;
    end
    else begin
        assign burst_addr_nxt_b = burst_addr_nxt; 
        assign error_w4KB       = 1'b0          ;       
    end
endgenerate

always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n) 
        st_cur <= BP_IDLE; 
    else 
        st_cur <= st_nxt;
end

always_comb begin
    case(st_cur)
        BP_FIRST: st_nxt = aff_re && aq_len>0 ? BP_BURST : st_cur; // if burst length is 1, won't jump to <BP_BURST>
        BP_BURST: st_nxt = burst_last ? (!bff_wfull ? BP_FIRST : BP_BRESP) : st_cur;
        BP_BRESP: st_nxt = !bff_wfull ? BP_FIRST : st_cur;
        BP_IDLE : st_nxt = BP_FIRST;
        default : st_nxt = BP_IDLE;
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        burst_cc   <= '0;
        burst_addr <= '0;
    end
    else if(st_cur==BP_FIRST) begin
        burst_cc   <= st_nxt==BP_BURST ? {{(AXI_BURSTW-1){1'b0}},1'b1} : 'x;
        burst_addr <= st_nxt==BP_BURST ? burst_addr_nxt_b[0 +: AXI_AW] : 'x;
    end
    else if(st_cur==BP_BURST) begin
        burst_cc   <= !wff_rempty ? burst_cc+1'b1 : burst_cc;
        burst_addr <= !wff_rempty ? burst_addr_nxt_b[0 +: AXI_AW] : burst_addr;
    end
end

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
    .wafull   (              ),
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
    .wafull   (              ),
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
    .wafull   (              ),
    .rempty   ( bff_rempty   ),
    .wcnt     ( bff_wcnt     ),
    .rcnt     ( bff_rcnt     ),
    .d        ( bff_d        ),
    .q        ( bff_q        )
);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        aq_id_latch    <= '0;
        aq_addr_latch  <= '0;
        aq_len_latch   <= '0;
        aq_size_latch  <= '0;
        aq_burst_latch <= '0;
    end
    else if(aff_re) begin
        aq_id_latch    <= aq_id   ;
        aq_addr_latch  <= aq_addr ;
        aq_len_latch   <= aq_len  ;
        aq_size_latch  <= aq_size ;
        aq_burst_latch <= aq_burst;
    end
end
endmodule

