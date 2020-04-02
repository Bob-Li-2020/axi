//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: Used in AXI4 DMA controller. Move data from local RAM to external memory via AXI4. 
//--              This module works in "clk" domain. To drive AXI bus, a Clock-Domain-Cross module
//--              is still needed to transfer to "ACLK" domain.

module axi_dma_w #(
    AXI_AW = 32,
    AXI_DW = 128,
    AXI_IW = 12,
    AXI_LW = 8,
    AXI_SW = 8,
    AXI_BURSTW = 3,
    AXI_WSTRBW = 16,
    AXI_BRESPW = 2,
    RAM_AW = 20,
    APB_AW = 12,
    BL     = 16,
    OD     = 4 // outstanding number
    //--derived parameters
    L = $clog2(AXI_DW/8),
    B = L+$clog2(BL)
)(
    //---- GLOBAL --------------------------
    input  logic                    clk     ,
    input  logic                    reset_n ,
    //---- APB ----------------------------------
    input  logic                    apb_we      ,
    input  logic [APB_AW-1:0]       apb_a       ,
    input  logic [31:0]             apb_d       ,
    output logic [31:0]             apb_q       ,
    //---- AXI AW ------------------------------
    output logic [AXI_IW-1     : 0] axi_awid    ,
    output logic [AXI_AW-1     : 0] axi_awaddr  ,
    output logic [AXI_LW-1     : 0] axi_awlen   ,
    output logic [AXI_SW-1     : 0] axi_awsize  ,
    output logic [AXI_BURSTW-1 : 0] axi_awburst ,
    output logic                    axi_awvalid ,
    input  logic                    axi_awready ,
    //---- AXI W  ------------------------------
    output logic [AXI_DW-1     : 0] axi_wdata   ,
    output logic [AXI_WSTRBW-1 : 0] axi_wstrb   ,
    output logic                    axi_wlast   ,
    output logic                    axi_wvalid  ,
    input  logic                    axi_wready  ,
    //---- AXI B -------------------------------
    input  logic [AXI_IW-1     : 0] axi_bid     ,
    input  logic [AXI_BRESPW-1 : 0] axi_bresp   ,
    input  logic                    axi_bvalid  ,
    output logic                    axi_bready  ,
    //---- USER W ------------------------------
    input  logic usr_wvalid,
    input  logic [AXI_DW-1:0] usr_wdata,
    input  logic usr_wlast,
    //--- interrupt
    output logic irq
);

timeprecision 1ps;
timeunit 1ns;

localparam 
ADDR_CR         = 0<<2, // CR
ADDR_SR         = 1<<2, // SR
ADDR_SRC_SA_LSB = 2<<2, // Source memory start address
ADDR_SRC_SA_MSB = 3<<2, // Source memory start address MSB
ADDR_DST_SA_LSB = 4<<2, // Destination memory start address("awaddr") dpos, dneg
ADDR_DST_SA_MSB = 5<<2, // Destination memory start address("awaddr") MSB. only used if AXI_AW>32
ADDR_DMA_LENGTH = 6<<2; // DMA length, word wise

typedef enum logic { IDLE=1'b0, BUSY } TYPE_DMA_STATE;
TYPE_DMA_STATE st_cur;
TYPE_DMA_STATE st_nxt;

// regs
logic [63:0] src_sa;
logic [63:0] dst_sa;
logic [31:0] dma_length;

logic [AXI_AW-1:0] dst_sa_nxt;
logic [31:0] dma_length_nxt;
logic dma_done;
logic dma_done_nxt; 
logic [$clog2(BL):0] a; 
logic a_less_equal_dma_length; 

assign dma_done_nxt = dma_done ? ~(apb_we && apb_a==ADDR_SR) : st_cur==BUSY && axi_awready && dma_length_nxt=='0;
assign a = {1'b0, ~dst_sa[L +: $clog2(BL)]} + 1'b1;
assign a_less_equal_dma_length = a <= dma_length;

//--------- outputs -------------------------
assign axi_awid = AXI_IW'(1);
assign axi_awaddr = dst_sa[AXI_AW-1:0];
assign axi_awsize = AXI_SW'($clog2(AXI_DW/8));
assign axi_awburst = AXI_BURSTW'(1); // AXI INC MODE
assign axi_awvalid = st_cur==IDLE && st_nxt==BUSY || st_cur==BUSY;
assign irq = dma_done;

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) 
        dma_done <= 1'b0;
    else
        dma_done <= dma_done_nxt;

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) 
        st_cur <= IDLE;
    else
        st_cur <= st_nxt;

always_comb 
    case(st_cur)
        IDLE   : st_nxt = dma_length>0 ? BUSY : st_cur;
        BUSY   : st_nxt = dma_done_nxt ? IDLE : st_cur;
        default: st_nxt = IDLE;
    endcase

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        src_sa     <= '0;
        dst_sa     <= '0;
        dma_length <= '0;
    end 
    else if(st_cur==IDLE && st_nxt==IDLE) begin
        src_sa[31: 0] <= apb_we && apb_a==ADDR_SRC_SA_LSB ? apb_d : src_sa[31: 0];
        src_sa[63:32] <= apb_we && apb_a==ADDR_SRC_SA_MSB ? apb_d : src_sa[63:32];
        dst_sa[31: 0] <= apb_we && apb_a==ADDR_DST_SA_LSB ? apb_d : dst_sa[31: 0];
        dst_sa[63:32] <= apb_we && apb_a==ADDR_DST_SA_MSB ? apb_d : dst_sa[63:32];
        dma_length    <= apb_we && apb_a==ADDR_DMA_LENGTH ? apb_d : dma_length;
    end 
    else if(st_cur==IDLE && st_nxt==BUSY || st_cur==BUSY) begin
        dst_sa[AXI_AW-1:0] <= axi_awready ? dst_sa_nxt : dst_sa[AXI_AW-1:0];
        dma_length <= axi_awready ? dma_length_nxt : dma_length;
    end

always_comb begin
    if(a_less_equal_dma_length) begin
        axi_awlen = {'0, ~axi_awaddr[L +: $clog2(BL)]};
        dst_sa_nxt = {axi_awaddr[AXI_AW-1:B]+1'b1, B'(0)};
        dma_length_nxt = dma_length - axi_awlen - 1'b1;
    end
    else begin
        axi_awlen = AXI_LW'(dma_length-1'b1);
        dst_sa_nxt = axi_awaddr+(AXI_LW'(dma_length)<<L);
        dma_length_nxt = '0;
    end
end

sfifo #(
    .DW(AXI_DW),
    .FW($clog2(OD)), // FW>0
    .SHOW_AHEAD(1)
) aw_buffer (
    .clk(clk),
    .rst_n(reset_n),
    .we(axi_awvalid & axi_awready),
    .re,
    .d,
    .q,
    .ne,
    .nf
);

// debug
always_ff @(posedge clk)
    if(axi_awvalid) begin
        $display("%t: axi_awvalid = %b; axi_awlen = %0d; axi_awaddr = %h", $realtime, axi_awvalid, axi_awlen, axi_awaddr);
    end

endmodule
