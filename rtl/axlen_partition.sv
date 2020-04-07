//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- Description: AXI burst length(write/read) partition, so that "axaddr" and "axlen" are burst length aligned.


module axlen_partition 
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
    AXI_BYTESW = $clog2(AXI_BYTES+1) ,  
    BL         = 16                  , // default burst length
    L          = $clog2(AXI_BYTES)   ,
    B          = $clog2(BL)+L 
)(
    input  logic                    clk           ,
    input  logic                    reset_n       ,
    //---- CONFIG ---------------------------------
    input  logic                    cfg_dma_valid ,
    output logic                    cfg_dma_ready ,
    input  logic [31           : 0] cfg_dma_sa    , // dma start address(bytes)   
    input  logic [31           : 0] cfg_dma_len   , // dma length(bytes) 
    //---- AXI AW/AR CHANNEL ----------------------
    output logic [AXI_IW-1     : 0] axid          ,
    output logic [AXI_AW-1     : 0] axaddr        ,
    output logic [AXI_LW-1     : 0] axlen         ,
    output logic [AXI_SW-1     : 0] axsize        ,
    output logic [AXI_BURSTW-1 : 0] axburst       ,
    output logic                    axvalid       ,
    input  logic                    axready        
);

timeunit 1ns;
timeprecision 1ps;

enum logic { IDLE=1'b0, BUSY } st_cur, st_nxt;

//---- CONFIG REGISTERS 
logic [31       : L] addr         ; // (word address)
logic [31       : L] len          ; // (word length)
logic                addr_we      ;
logic                len_we       ;

logic [AXI_LW-1 : 0] axlen_prompt ;
logic                addr_last    ;

assign addr_we       = st_cur==IDLE && st_nxt==BUSY;
assign len_we        = st_cur==IDLE && st_nxt==BUSY;
assign cfg_dma_ready = st_cur==IDLE      ;
assign axid          = AXI_IW'(1)        ;
assign axaddr        = {addr[AXI_AW-1:L], L'(0)};
assign axlen         = min2_len(axlen_prompt, len);
assign axsize        = AXI_SW'($clog2(AXI_BYTES));
assign axburst       = AXI_BURSTW'(1)    ;
assign axvalid       = st_cur==BUSY      ;
assign axlen_prompt  = {'0, ~addr[B-1:L]};
assign addr_last     = axvalid & axready && len-axlen-1'b1=='0;

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        st_cur <= IDLE;
    end
    else begin
        st_cur <= st_nxt;
    end

always_comb 
    case(st_cur)
        IDLE: st_nxt = cfg_dma_ready & cfg_dma_valid && cfg_dma_len>0 ? BUSY : st_cur;
        BUSY: st_nxt = addr_last ? IDLE : st_cur;
        default:  st_nxt = IDLE;
    endcase

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        addr <= '0;
    end 
    else if(st_cur==IDLE && addr_we) begin
        addr <= cfg_dma_sa[31:L];
    end
    else if(st_cur==BUSY && axvalid & axready) begin
        addr <= addr+axlen+1'b1;
    end

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) begin
        len <= '0;
    end 
    else if(st_cur==IDLE && len_we) begin
        len <= cfg_dma_len[31:L];
    end
    else if(st_cur==BUSY && axvalid & axready) begin
        len <= len-axlen-1'b1;
    end

function logic [AXI_LW-1:0] min2_len(input logic [AXI_LW-1:0] axlen, input logic [31:L] len);
    return axlen < len-1'b1 ? axlen : AXI_LW'(len-1'b1);
endfunction: min2_len

endmodule

