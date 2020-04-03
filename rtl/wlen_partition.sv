module wlen_partition 
#(
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 32                  , // AXI ADDRESS BUS WIDTH(MUST <= 32)
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
    //---- USER GLOBAL -----------------------------
    input  logic                    usr_clk        ,
    input  logic                    usr_reset_n    ,
    //---- CONFIG DMA WRITE ------------------------
    input  logic                    cfg_dmaw_valid ,
    output logic                    cfg_dmaw_ready ,
    input  logic [31           : 0] cfg_dmaw_sa    , // dma write start address   
    input  logic [31           : 0] cfg_dmaw_len   , // dma write length in bytes
    //---- USER AW ---------------------------------
    output logic [AXI_IW-1     : 0] usr_awid       ,
    output logic [AXI_AW-1     : 0] usr_awaddr     ,
    output logic [AXI_LW-1     : 0] usr_awlen      ,
    output logic [AXI_SW-1     : 0] usr_awsize     ,
    output logic [AXI_BURSTW-1 : 0] usr_awburst    ,
    output logic                    usr_awvalid    ,
    input  logic                    usr_awready    ,
    //---- USER W  ---------------------------------
    output logic [AXI_DW-1     : 0] usr_wdata      ,
    output logic [AXI_WSTRBW-1 : 0] usr_wstrb      ,
    output logic                    usr_wlast      ,
    output logic                    usr_wvalid     ,
    input  logic                    usr_wready     ,
    //---- USER B  ---------------------------------
    output logic [AXI_IW-1     : 0] usr_bid        ,
    output logic [AXI_BRESPW-1 : 0] usr_bresp      ,
    output logic                    usr_bvalid     ,
    input  logic                    usr_bready     ,
    //---- DMA WRITE DATA --------------------------
    input  logic [AXI_DW-1     : 0] dmaw_data      ,
    input  logic [AXI_WSTRBW-1 : 0] dmaw_strb      ,
    input  logic                    dmaw_last      ,
    input  logic                    dmaw_valid     ,
    output logic                    dmaw_ready      
);

timeunit 1ns;
timeprecision 1ps;

localparam 
BL = 16, // default burst length
L = $clog2(AXI_BYTES),
B = $clog2(BL)+L;

enum logic [1:0] { CFG_IDLE=2'b00, CFG_BUSY, CFG_EXIT } st_cur, st_nxt;

//---- CONFIG REGISTERS -------
logic [31 : L] dmaw_sa        ;
logic [31 : L] dmaw_len       ;
logic [31 : L] dmaw_data_len  ; // static version of "dmaw_len"
logic          dmaw_data_last ;
logic [31 : L] dmaw_data_cc   ;

//---- OUTPUTS ----------------
//---- CONFIG DMA WRITE ------------------------

output logic                    cfg_dmaw_ready = st_cur==CFG_IDLE;


//---- USER AW ---------------------------------
output logic [AXI_IW-1     : 0] usr_awid       = AXI_IW'(1);
output logic [AXI_AW-1     : 0] usr_awaddr     ,
output logic [AXI_LW-1     : 0] usr_awlen      ,
output logic [AXI_SW-1     : 0] usr_awsize     = AXI_SW'($clog2(AXI_BYTES));
output logic [AXI_BURSTW-1 : 0] usr_awburst    = AXI_BURSTW'(1);
output logic                    usr_awvalid    ,

//---- USER W  ---------------------------------
output logic [AXI_DW-1     : 0] usr_wdata      = dmaw_data;
output logic [AXI_WSTRBW-1 : 0] usr_wstrb      = dmaw_strb;
output logic                    usr_wlast      = ,
output logic                    usr_wvalid     ,

//---- USER B  ---------------------------------
output logic [AXI_IW-1     : 0] usr_bid        ,
output logic [AXI_BRESPW-1 : 0] usr_bresp      ,
output logic                    usr_bvalid     ,

//---- DMA WRITE DATA --------------------------




output logic                    dmaw_ready      


assign {usr_awid, usr_awsize, usr_awburst} = {AXI_IW'(1), AXI_SW'($clog2(AXI_BYTES)), AXI_BURSTW'(1)};
assign usr_awvalid    = ~cfg_dmaw_ready && dmaw_len>0;
assign usr_awaddr     = {dmaw_sa[AXI_AW-1:L], '0};
assign usr_awlen      = 
assign dmaw_ready     = ~cfg_dmaw_ready & usr_wready;
assign dmaw_data_last = dmaw_valid & dmaw_ready && dmaw_data_cc+1'b1==dmaw_data_len;

always_ff @(posedge usr_clk or negedge usr_reset_n)
    if(!usr_reset_n) begin
        st_cur <= CFG_IDLE;
    end
    else begin
        st_cur <= st_nxt;
    end

always_comb 
    case(st_cur)
        CFG_IDLE: cfg_dmaw_ready & cfg_dmaw_valid && cfg_dmaw_len>0 ? CFG_BUSY : st_cur;
        CFG_BUSY: //TODO
    endcase

always_ff @(posedge usr_clk or negedge usr_reset_n)
    if(!usr_reset_n) begin
        dmaw_sa <= '0;
        dmaw_len <= '0;
        dmaw_data_len <= '0;
    end 
    else if(st_cur==CFG_IDLE && st_nxt==CFG_BUSY) begin
        dmaw_sa <= cfg_dmaw_sa[31:L];
        dmaw_len <= cfg_dmaw_len[31:L]; 
        dmaw_data_len <= cfg_dmaw_len[31:L]; 
    end

always_ff @(posedge usr_clk or negedge usr_reset_n)
    if(!usr_reset_n) begin
        dmaw_data_cc <= '0;
    end
    else if(dmaw_valid & dmaw_ready) begin
        dmaw_data_cc <= dmaw_data_last ? '0 : dmaw_data_cc+1'b1;
    end


endmodule

