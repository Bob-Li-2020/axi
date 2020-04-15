//-- AUTHOR: LIBING
//-- DATE: 2019.12
//-- DESCRIPTION: AXI SLAVE INTERFACE.READ. BASED ON AXI4 SPEC.


// asi_r: Axi Slave Interface Read
module asi_r 
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
    //---- READ ADDRESS CHANNEL ---------------------
    input  logic [AXI_IW-1     : 0] ARID            ,
    input  logic [AXI_AW-1     : 0] ARADDR          ,
    input  logic [AXI_LW-1     : 0] ARLEN           ,
    input  logic [AXI_SW-1     : 0] ARSIZE          ,
    input  logic [AXI_BURSTW-1 : 0] ARBURST         ,
    input  logic                    ARVALID         ,
    output logic                    ARREADY         ,
    //---- READ DATA CHANNEL ------------------------
    output logic [AXI_IW-1     : 0] RID             ,
    output logic [AXI_DW-1     : 0] RDATA           ,
    output logic [AXI_RRESPW-1 : 0] RRESP           ,
    output logic                    RLAST           ,
    output logic                    RVALID          ,
    input  logic                    RREADY          ,
    //---- USER LOGIC SIGNALS -----------------------
    input  logic                    usr_clk         ,
    input  logic                    usr_reset_n     ,
    //AR CHANNEL
    output logic [AXI_IW-1     : 0] usr_rid         ,
    output logic [AXI_LW-1     : 0] usr_rlen        ,
    output logic [AXI_SW-1     : 0] usr_rsize       ,
    output logic [AXI_BURSTW-1 : 0] usr_rburst      ,
    //R CHANNEL
    output logic [AXI_AW-1     : 0] usr_raddr       ,
    output logic                    usr_re          ,
    output logic                    usr_rlast       ,
    input  logic [AXI_DW-1     : 0] usr_rdata       ,
    //ARBITER SIGNALS
    output logic                    usr_rrequest    , // arbiter read request
    input  logic                    usr_rgrant      , // arbiter read grant
    //ERROR FLAGS
    input  logic                    usr_rsize_error   // unsupported transfer size
);

timeunit 1ns;
timeprecision 1ps;
//------------------------------------
//------ INTERFACE PARAMETERS --------
//------------------------------------
localparam AFF_DW = AXI_IW + AXI_AW + AXI_LW + AXI_SW + AXI_BURSTW,
           RFF_DW = AXI_IW + AXI_DW + AXI_RRESPW + 1;
localparam OADDR_DEPTH = ASI_AD , // outstanding addresses buffer depth
           RDATA_DEPTH = ASI_RD , // read data buffer depth
           AFF_AW = $clog2(OADDR_DEPTH),
           RFF_AW = $clog2(RDATA_DEPTH);
localparam [AXI_BURSTW-1 : 0] BT_FIXED     = AXI_BURSTW'(0);
localparam [AXI_BURSTW-1 : 0] BT_INCR      = AXI_BURSTW'(1);
localparam [AXI_BURSTW-1 : 0] BT_WRAP      = AXI_BURSTW'(2);
localparam [AXI_BURSTW-1 : 0] BT_RESERVED  = AXI_BURSTW'(3);
//------------------------------------
//------ BURST PHASE DATA TYPE -------
//------------------------------------
// BP_FIRST: transfer the first transfer
// BP_BURST: transfer the rest  transfer(s)
// BP_IDLE : do nothing
typedef enum logic [1:0] { BP_FIRST=2'b00, BP_BURST, BP_IDLE } RBURST_PHASE; 
//------ TOP PORTS ------------------------
logic                    usr_rvalid       ;
//-----------------------------------------
//------ EASY SIGNALS ---------------------
//-----------------------------------------
wire                     clk              ;
wire                     rst_n            ;
wire                     aff_rvalid       ;
wire                     aff_rready       ;
//-----------------------------------------
//------ AR CHANNEL FIFO SIGNALS ----------
//-----------------------------------------
logic                    aff_wreset_n     ;
logic                    aff_rreset_n     ;
logic                    aff_wclk         ;
logic                    aff_rclk         ;
logic                    aff_we           ;
logic                    aff_re           ;
logic                    aff_wfull        ;
logic                    aff_rempty       ;
logic [AFF_AW       : 0] aff_wcnt         ;
logic [AFF_DW-1     : 0] aff_d            ;
logic [AFF_DW-1     : 0] aff_q            ;
//-----------------------------------------
//------ R CHANNEL FIFO SIGNALS -----------
//-----------------------------------------
logic                    rff_wreset_n     ;
logic                    rff_rreset_n     ;
logic                    rff_wclk         ;
logic                    rff_rclk         ;
logic                    rff_we           ;
logic                    rff_re           ;
logic                    rff_wfull        ;
logic                    rff_wafull       ;
logic                    rff_rempty       ;
logic [RFF_AW       : 0] rff_wcnt         ;
logic [RFF_DW-1     : 0] rff_d            ;
logic [RFF_DW-1     : 0] rff_q            ;
//-----------------------------------------
logic                    rff_wafull2      ;
//-----------------------------------------
//------ AR FIFO Q SIGNALS ----------------
//-----------------------------------------
logic [AXI_IW-1     : 0] aq_id            ;
logic [AXI_AW-1     : 0] aq_addr          ;
logic [AXI_LW-1     : 0] aq_len           ;
logic [AXI_SW-1     : 0] aq_size          ;
logic [AXI_BURSTW-1 : 0] aq_burst         ;
//-----------------------------------------
//------ AR FIFO Q SIGNALS LATCH ----------
//-----------------------------------------
logic [AXI_IW-1     : 0] aq_id_latch      ;
logic [AXI_AW-1     : 0] aq_addr_latch    ;
logic [AXI_LW-1     : 0] aq_len_latch     ;
logic [AXI_SW-1     : 0] aq_size_latch    ;
logic [AXI_BURSTW-1 : 0] aq_burst_latch   ;
//-----------------------------------------
//------ R FIFO Q SIGNALS -----------------
//-----------------------------------------
logic [AXI_IW-1     : 0] rq_id            ;
logic [AXI_DW-1     : 0] rq_data          ;
logic [AXI_RRESPW-1 : 0] rq_resp          ;
logic                    rq_last          ;
//-----------------------------------------
//------ AXI BURST ADDRESSES --------------
//-----------------------------------------
logic [AXI_BYTESW-1 : 0] burst_addr_inc   ;
logic [AXI_AW-0     : 0] burst_addr_nxt   ;
logic [AXI_AW-0     : 0] burst_addr_nxt_b ; // bounded to 4KB 
logic [AXI_AW-1     : 0] burst_addr       ;
logic [AXI_LW-1     : 0] burst_cc         ;
logic [AXI_AW-1     : 0] start_addr       ;
logic [AXI_AW-1     : 0] start_addr_mask  ;
logic [AXI_AW-1     : 0] aligned_addr     ;
//-----------------------------------------
//------ R FIFO D SIGNALS -----------------
//-----------------------------------------
logic [AXI_RRESPW-1 : 0] usr_rresp_ws     ;
logic                    burst_last_ws    ;
logic [AXI_IW-1     : 0] usr_rid_ws       ;
//-----------------------------------------
//------ TRANSFER SIZE ERROR --------------
//-----------------------------------------
logic                    trsize_err       ;
//-----------------------------------------
//------ READ RESPONSE VALUE --------------
//-----------------------------------------
logic [AXI_RRESPW-1 : 0] usr_rresp        ;
//-----------------------------------------
//------ STATE MACHINE VARIABLES ----------
//-----------------------------------------
logic                    burst_last       ;
RBURST_PHASE             st_cur          ;
RBURST_PHASE             st_nxt          ; 
//-------------------------------------------------- LOGIC DESIGNS -----------------------------------------------------//
//------ WS(Wait States) control
generate 
    if(SLV_WS==0) begin: WS0
        assign usr_rvalid  = usr_re;
        assign rff_wafull2 = rff_wcnt >= RDATA_DEPTH;
    end: WS0
    else begin: WS_N
        logic [SLV_WS : 0] usr_re_ff   ;
        logic [RFF_AW : 0] rff_wcnt_af ; // rff wcnt almost full
        assign usr_rvalid  = usr_re_ff[SLV_WS-1];
        assign rff_wafull2 = rff_wcnt_af >= RDATA_DEPTH;
        always_ff @(posedge usr_clk or negedge usr_reset_n)
            if(!usr_reset_n)
                usr_re_ff <= '0;
            else
                usr_re_ff <= {usr_re_ff[SLV_WS-1:0], usr_re};
        always_comb begin
            rff_wcnt_af = rff_wcnt;
            for(int k=0;k<SLV_WS;k++) begin
                rff_wcnt_af = rff_wcnt_af+usr_re_ff[k];
            end
        end
    end: WS_N
endgenerate

//------------------------------------
//------ OUTPUT PORTS ASSIGN ---------
//------------------------------------
//-- AXI HANDSHAKES
assign ARREADY          = ~aff_wfull       ;
//-- R CHANNEL 
assign RID              = rq_id            ;
assign RDATA            = rq_data          ;
assign RRESP            = rq_resp          ;
assign RLAST            = rq_last          ;
assign RVALID           = ~rff_rempty      ;
//-- USER LOGIC
assign usr_rid          = st_cur==BP_FIRST ? aq_id    : aq_id_latch;
assign usr_rlen         = st_cur==BP_FIRST ? aq_len   : aq_len_latch;
assign usr_rsize        = st_cur==BP_FIRST ? aq_size  : aq_size_latch;
assign usr_rburst       = st_cur==BP_FIRST ? aq_burst : aq_burst_latch;
assign usr_raddr        = st_cur==BP_FIRST ? start_addr : burst_addr;
assign usr_re           = aff_re || st_cur==BP_BURST && (!rff_wafull2);
assign usr_rlast        = burst_last       ;
assign usr_rrequest     = !aff_rempty && !(usr_re && aq_len=='0 && st_cur==BP_FIRST);
assign error_w4KB       = burst_addr_nxt[12]!=start_addr[12] && st_cur==BP_BURST;
//------------------------------------
//------ EASY ASSIGNMENTS ------------
//------------------------------------
assign clk              = usr_clk          ;
assign rst_n            = usr_reset_n      ;
assign aff_rvalid       = !aff_rempty      ; 
assign aff_rready       = st_cur==BP_FIRST && ~rff_wafull2 & usr_rgrant;
//------------------------------------
//------ AR CHANNEL FIFO ASSIGN ------
//------------------------------------
assign aff_wreset_n     = ARESETn          ;
assign aff_rreset_n     = usr_reset_n      ;
assign aff_wclk         = ACLK             ;
assign aff_rclk         = usr_clk          ;
assign aff_we           = ARVALID & ARREADY;
assign aff_re           = aff_rvalid & aff_rready;
assign aff_d            = { ARID, ARADDR, ARLEN, ARSIZE, ARBURST };
assign { aq_id, aq_addr, aq_len, aq_size, aq_burst } = aff_q;
//------------------------------------
//------ R CHANNEL FIFO ASSIGN -------
//------------------------------------
assign rff_wreset_n     = usr_reset_n      ;
assign rff_rreset_n     = ARESETn          ;
assign rff_wclk         = usr_clk          ;
assign rff_rclk         = ACLK             ;
assign rff_we           = usr_rvalid       ;
assign rff_re           = RVALID & RREADY  ;
assign rff_d            = { usr_rid_ws, usr_rdata, usr_rresp_ws, burst_last_ws }; 
assign { rq_id, rq_data, rq_resp, rq_last } = rff_q;
//------------------------------------
//------ TRANSFER SIZE ERROR ---------
//------------------------------------
assign trsize_err       = (usr_rsize > (AXI_SW'($clog2(AXI_BYTES)))) | usr_rsize_error;
//------------------------------------
//------ READ RESPONSE VALUE ---------
//------------------------------------
assign usr_rresp        = { trsize_err, 1'b0 };
//------------------------------------
//------ ADDRESS CALCULATION ---------
//------------------------------------
assign burst_addr_inc   = usr_rburst==BT_FIXED ? '0 : (AXI_BYTESW'(1))<<usr_rsize;
assign burst_addr_nxt   = st_cur==BP_FIRST ? (burst_addr_inc+aligned_addr) : (st_cur==BP_BURST ? (!rff_wafull2 ? burst_addr_inc+burst_addr : burst_addr) : 'x);
assign burst_addr_nxt_b = burst_addr_nxt[12]==start_addr[12] ? burst_addr_nxt : (st_cur==BP_FIRST ? aligned_addr : st_cur==BP_BURST ? burst_addr : 'x);
assign start_addr       = st_cur==BP_FIRST ? aq_addr : aq_addr_latch;
assign aligned_addr     = start_addr_mask & start_addr;
always_comb begin
    start_addr_mask = ('1)<<($clog2(AXI_BYTES)); // default align with AXI_DATA_BUS_BYTES
	for(int i=0;i<=($clog2(AXI_BYTES));i++) begin
		if(i==usr_rsize) begin
            start_addr_mask = ('1)<<i;
		end
	end
end
//------------------------------------
//------ STATE MACHINES CONTROL ------
//------------------------------------
assign burst_last = (usr_re && aq_len=='0 && st_cur==BP_FIRST) || (burst_cc==aq_len_latch && (!rff_wafull2) && st_cur==BP_BURST);
always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n) 
        st_cur <= BP_IDLE; 
    else 
        st_cur <= st_nxt;
end
always_comb 
    case(st_cur)
        BP_FIRST: st_nxt = aff_re && aq_len ? BP_BURST : st_cur;
        BP_BURST: st_nxt = burst_last ? BP_FIRST : st_cur;
        BP_IDLE : st_nxt = BP_FIRST;
        default : st_nxt = BP_IDLE;
    endcase
always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        burst_cc   <= '0;
        burst_addr <= '0;
    end
    else if(st_cur==BP_FIRST) begin
        burst_cc   <= st_nxt==BP_BURST ? AXI_BURSTW'(1) : 'x;
        burst_addr <= st_nxt==BP_BURST ? burst_addr_nxt_b[0 +: AXI_AW] : 'x;
    end
    else if(st_cur==BP_BURST) begin
        burst_cc   <= burst_cc+(!rff_wafull2);
        burst_addr <= burst_addr_nxt_b[0 +: AXI_AW];
    end
end
//------------------------------------
//------ R FIFO D SIGNALS ------------
//------------------------------------
generate 
    if(SLV_WS==0) begin: INFO_WS0
        assign usr_rresp_ws  = usr_rresp ;
        assign burst_last_ws = burst_last;
        assign usr_rid_ws    = usr_rid   ;
    end: INFO_WS0
    else if(SLV_WS==1) begin: INFO_WS1
        always_ff @(posedge clk)
            {usr_rresp_ws, burst_last_ws, usr_rid_ws} <= {usr_rresp, burst_last, usr_rid};
    end: INFO_WS1
    else begin: INFO_WSN
        wire  [AXI_RRESPW+1+AXI_IW-1 : 0] rfd_sigs = {usr_rresp, burst_last, usr_rid};
        logic [AXI_RRESPW+1+AXI_IW-1 : 0] rfd_sigs_ff[SLV_WS] ;
        always_ff @(posedge clk) begin
            rfd_sigs_ff[0] <= rfd_sigs;
            for(int i=1;i<SLV_WS;i++) 
                rfd_sigs_ff[i] <= rfd_sigs_ff[i-1];
        end
        assign {usr_rresp_ws, burst_last_ws, usr_rid_ws} = rfd_sigs_ff[SLV_WS-1];
    end: INFO_WSN
endgenerate
//------------------------------------
//------ AR FIFO Q SIGNALS LATCH -----
//------------------------------------
always_ff @(posedge clk) begin
    if(aff_re) begin
        aq_id_latch    <= aq_id;
        aq_addr_latch  <= aq_addr;
        aq_len_latch   <= aq_len;
        aq_size_latch  <= aq_size;
        aq_burst_latch <= aq_burst;
    end
end
//------------------------------------
//------ AR CHANNEL BUFFER -----------
//------------------------------------
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
    .wafull   (              ),
    .rempty   ( aff_rempty   ),
    .wcnt     ( aff_wcnt     ),
    .d        ( aff_d        ),
    .q        ( aff_q        )
);
//------------------------------------
//------ R CHANNEL BUFFER ------------
//------------------------------------
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
    .wafull   (              ),
    .rempty   ( rff_rempty   ),
    .wcnt     ( rff_wcnt     ),
    .d        ( rff_d        ),
    .q        ( rff_q        )
);

endmodule

