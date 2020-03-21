module tb;

timeprecision 1ps;
timeunit 1ns;

//--clocks & reset
localparam
CLK0_T = 2.0, // clk0 period(ns)
CLK0_P = 0.2, // clk0 initial phase(ns)
CLK0_J = 0.1, // clk0 maximum jitter(ns)
CLK1_T = 2.0, // clk1 period(ns)
CLK1_P = 0.4, // clk1 initial phase(ns)
CLK1_J = 0.1, // clk1 maximum jitter(ns)
RESET0_P = 10.1,
RESET1_P = 11.2;

//-- RAM
localparam
RAM_SZ = 512 , // RAM DEPTH 
RAM_BW = 8   , // BYTE WIDTH
RAM_BS = 4   , // BYTES NUMBER IN A WORD
RAM_QX = 0   , // 
RAM_WS = 1   , // READ WAIT STATES
//--- derived parameters
RAM_AW = $clog2(RAM_SZ) , 
RAM_DW = RAM_BW*RAM_BS  ;       

//-- clocks & reset
bit stop;
bit clk0;
bit clk1;
bit rst0;
bit rst1;

//-- RAMSP
logic              RAM_CLK;
logic              RAM_CEN;
logic [RAM_BS-1:0] RAM_WEN;
logic [RAM_AW-1:0] RAM_A  ;
logic [RAM_DW-1:0] RAM_D  ;
logic [RAM_DW-1:0] RAM_Q  ;

//-- RAMSP
assign RAM_CLK = clk0;

reset_gen #(
    .RESET0_P(RESET0_P),
    .RESET1_P(RESET1_P)
) RESETGEN (
    .stop,
    .rst0,
    .rst1
);

clk_gen #(
    .CLK0_T(CLK0_T), 
    .CLK0_P(CLK0_P), 
    .CLK0_J(CLK0_J), 
    .CLK1_T(CLK1_T), 
    .CLK1_P(CLK1_P), 
    .CLK1_J(CLK1_J)  
) CLKGEN (
    .stop,
    .clk0,
    .clk1
);

initial begin
    $timeformat(-9, 5, "ns", 8);
    fork
        RAM_CEN <= '1;
        RAM_WEN <= '1;
        @(negedge rst0);
        @(negedge rst1);
    join
    @(posedge RAM_CLK);
    write_ram(0,100);
    read_ram(0);
    #100;
    stop = 1;
end

// -- test
task write_ram(input int addr, data);
    RAM_A   <= addr;
    RAM_D   <= data;
    RAM_CEN <= '0;
    RAM_WEN <= '0;
    @(posedge RAM_CLK);
    RAM_CEN <= '1;
    RAM_WEN <= '1;
    $display("%0t: RAM_WRITE: addr = %0d; data = %0d", $realtime, addr, data);
endtask

task read_ram(input int addr);
    RAM_A   <= addr;
    RAM_CEN <= '0;
    @(posedge RAM_CLK);
    RAM_A   <= 'x;
    RAM_CEN <= '1;
    #1;
    $display("%0t: RAM_READ: addr = %0d; Q = %0d", $realtime, addr, RAM_Q);
    repeat(RAM_WS) @(posedge RAM_CLK);
    $display("%0t: RAM_READ(WS): addr = %0d; Q = %0d", $realtime, addr, RAM_Q);
endtask

RAMSP #(
    .SZ ( RAM_SZ ), // RAM DEPTH 
    .BW ( RAM_BW ), // BYTE WIDTH
    .BS ( RAM_BS ), // BYTES NUMBER IN A WORD
    .QX ( RAM_QX ), // 
    .WS ( RAM_WS )  // READ WAIT STATES
) U_RAM (
    .CLK( RAM_CLK ),
    .CEN( RAM_CEN ),
    .WEN( RAM_WEN ),
    .A  ( RAM_A   ),
    .D  ( RAM_D   ),
    .Q  ( RAM_Q   )
);

endmodule
