//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- Description: DMA.WRITE AXI burst length partition


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
    input  logic                    clk            ,
    input  logic                    reset_n        ,
    //---- CONFIG ----------------------------------
    input  logic                    cfg_dmaw_valid ,
    output logic                    cfg_dmaw_ready ,
    input  logic [31           : 0] cfg_dmaw_sa    , // dma write start address   
    input  logic [31           : 0] cfg_dmaw_len   , // dma write length 
    //---- AXI AW CHANNEL --------------------------
    output logic [AXI_IW-1     : 0] awid           ,
    output logic [AXI_AW-1     : 0] awaddr         ,
    output logic [AXI_LW-1     : 0] awlen          ,
    output logic [AXI_SW-1     : 0] awsize         ,
    output logic [AXI_BURSTW-1 : 0] awburst        ,
    output logic                    awvalid        ,
    input  logic                    awready         
);

timeunit 1ns;
timeprecision 1ps;

localparam 
BL = 16, // default burst length
L = $clog2(AXI_BYTES),
B = $clog2(BL)+L;

enum logic { IDLE=1'b0, BUSY } st_cur, st_nxt;

//---- CONFIG REGISTERS ----
logic [31 : L] dmaw_sa     ;
logic [31 : L] dmaw_len    ;
logic          dmaw_sa_we  ;
logic          dmaw_len_we ;

assign dmaw_sa_we  = st_cur==IDLE && st_nxt==BUSY;
assign dmaw_len_we = st_cur==IDLE && st_nxt==BUSY;

logic [AXI_LW-1 : 0] awlen_prompt ;
logic                dmaw_sa_last ;

assign cfg_dmaw_ready = st_cur==IDLE       ;
assign awid           = AXI_IW'(1)         ;
assign awaddr         = {dmaw_sa[AXI_AW-1:L], L'(0)};
assign awlen          = min2_len(awlen_prompt, dmaw_len);
assign awsize         = AXI_SW'($clog2(AXI_BYTES));
assign awburst        = AXI_BURSTW'(1)     ;
assign awvalid        = st_cur==BUSY       ;
assign awlen_prompt   = {'0, ~dmaw_sa[B-1:L]};
assign dmaw_sa_last   = awvalid & awready && dmaw_len-awlen-1'b1=='0;

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        st_cur <= IDLE;
    end
    else begin
        st_cur <= st_nxt;
    end

always_comb 
    case(st_cur)
        IDLE: st_nxt = cfg_dmaw_ready & cfg_dmaw_valid && cfg_dmaw_len>0 ? BUSY : st_cur;
        BUSY: st_nxt = dmaw_sa_last ? IDLE : st_cur;
        default:  st_nxt = IDLE;
    endcase

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        dmaw_sa <= '0;
    end 
    else if(st_cur==IDLE && dmaw_sa_we) begin
        dmaw_sa <= cfg_dmaw_sa[31:L];
    end
    else if(st_cur==BUSY && awvalid & awready) begin
        dmaw_sa <= dmaw_sa+awlen+1'b1;
    end

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        dmaw_len <= '0;
    end 
    else if(st_cur==IDLE && dmaw_len_we) begin
        dmaw_len <= cfg_dmaw_len[31:L];
    end
    else if(st_cur==BUSY && awvalid & awready) begin
        dmaw_len <= dmaw_len-awlen-1'b1;
    end

function logic [AXI_LW-1:0] min2_len(input logic [AXI_LW-1:0] awlen, input logic [31:L] dmaw_len);
    return awlen < dmaw_len-1'b1 ? awlen : AXI_LW'(dmaw_len-1'b1);
endfunction: min2_len

endmodule

