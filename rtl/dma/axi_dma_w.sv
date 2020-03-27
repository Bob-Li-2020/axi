//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: Used in AXI4 DMA controller. Move data from local RAM to external memory via AXI4. 
//--              This module works in "usr_clk" domain. To drive AXI bus, a Clock-Domain-Cross module
//--              is still needed to transfer to "ACLK" domain.

module axi_dma_w #(
    AXI_AW = 32,
    RAM_AW = 20,
    APB_AW = 12
)(
    //---- CONTROL --------------------------
    input  logic                    apb_clk     ,
    input  logic                    apb_reset_n ,
    input  logic [APB_AW-1:0]       apb_a       ,
    input  logic [31:0]             apb_d       ,
    output logic [31:0]             apb_q       ,
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

localparam 
ADDR_CR         = 0<<2, // DMA enable
ADDR_SRC_SA_LSB = 1<<2, // Source memory start address
ADDR_SRC_SA_MSB = 2<<2, // Source memory start address MSB
ADDR_DST_SA_LSB = 3<<2, // Destination memory start address("awaddr") dpos, dneg
ADDR_DST_SA_MSB = 4<<2, // Destination memory start address("awaddr") MSB. only used if AXI_AW>32
ADDR_DMA_LENGTH = 5<<2; // DMA length, word wise

typedef enum logic { IDLE=1'b0, BUSY } TYPE_DMA_STATE;
TYPE_DMA_STATE st_cur;
TYPE_DMA_STATE st_nxt;

reg [31:0] cr;
reg [31:0] src_sa_lsb;
reg [31:0] src_sa_msb;
reg [31:0] dst_sa_lsb;
reg [31:0] dst_sa_msb;
reg [31:0] dma_len;

wire [RAM_AW-1:0] src_sa = {src_sa_msb, src_sa_lsb};
wire [AXI_AW-1:0] dst_sa = {dst_sa_msb, dst_sa_lsb};
wire              dma_en = cr[0];

logic dma_done;

always_ff @(posedge apb_clk or negedge apb_reset_n)
    if(!apb_reset_n) begin
        cr         <= '0;
        src_sa_lsb <= '0;
        src_sa_msb <= '0;
        dst_sa_lsb <= '0;
        dst_sa_msb <= '0;
        dma_len    <= '0;
    end else if(st_cur==IDLE && apb_we) begin
        cr         <= apb_a==ADDR_CR         ? apb_d : cr;
        src_sa_lsb <= apb_a==ADDR_SRC_SA_LSB ? apb_d : src_sa_lsb;
        src_sa_msb <= apb_a==ADDR_SRC_SA_MSB ? apb_d : src_sa_msb;
        dst_sa_lsb <= apb_a==ADDR_DST_SA_LSB ? apb_d : dst_sa_lsb;
        dst_sa_msb <= apb_a==ADDR_DST_SA_MSB ? apb_d : dst_sa_msb;
        dma_len    <= apb_a==ADDR_DMA_LENGTH ? apb_d : dma_len;
    end else if(st_cur==BUSY && dma_done) begin
        cr[0] <= 1'b0;
    end

endmodule
