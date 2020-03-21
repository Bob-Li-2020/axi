module RAMSP #(
    SZ = 512        , // RAM DEPTH 
    BW = 8          , // BYTE WIDTH
    BS = 4          , // BYTES NUMBER IN A WORD
    QX = 0          , // 
    WS = 0          , // READ WAIT STATES
    //--- derived parameters
    AW = $clog2(SZ) , 
    DW = BW*BS       
)(
    input  logic CLK,
    input  logic CEN,
    input  logic [BS-1:0] WEN,
    input  logic [AW-1:0] A,
    input  logic [DW-1:0] D,
    output logic [DW-1:0] Q
);

timeprecision 1ps;
timeunit 1ns;

integer i;
genvar j;
reg [DW-1:0] mem [SZ-1:0];

// WRITE:
always @(posedge CLK) if(~CEN) for(i=0;i<BS;i=i+1) if (~WEN[i]) mem[A][i*BW+:BW] <= D[i*BW+:BW];

// READ WAIT SATTES CONTROL:
generate 

    if(WS==0) begin: WS0
        assign Q = mem[A];
    end: WS0

    else if(WS==1) begin: WS1
        always @(posedge CLK) if (~CEN) Q <= mem[A]; else if (QX) Q <= {DW{1'bx}};
    end: WS1

    else if(WS>=2) begin: WS2
        logic [DW-1:0] q_ff[WS-1:0];

        always @(posedge CLK) if (~CEN) q_ff[0] <= mem[A]; else if (QX) q_ff[0] <= {DW{1'bx}};
        for(j=1;j<=WS-1;j++) begin always_ff @(posedge CLK) q_ff[j] <= q_ff[j-1]; end
        assign Q = q_ff[WS-1];
    end: WS2

endgenerate

endmodule
