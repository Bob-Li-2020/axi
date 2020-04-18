// top: fpga
// description: to test asi(Axi Slave Interface)

module fpga (
    input  wire         FPGA_CLK,
    output wire [12:0]  memory_mem_a,               //             memory.mem_a
    output wire [2:0]   memory_mem_ba,              //                   .mem_ba
    output wire         memory_mem_ck,              //                   .mem_ck
    output wire         memory_mem_ck_n,            //                   .mem_ck_n
    output wire         memory_mem_cke,             //                   .mem_cke
    output wire         memory_mem_cs_n,            //                   .mem_cs_n
    output wire         memory_mem_ras_n,           //                   .mem_ras_n
    output wire         memory_mem_cas_n,           //                   .mem_cas_n
    output wire         memory_mem_we_n,            //                   .mem_we_n
    output wire         memory_mem_reset_n,         //                   .mem_reset_n
    inout  wire [7:0]   memory_mem_dq,              //                   .mem_dq
    inout  wire         memory_mem_dqs,             //                   .mem_dqs
    inout  wire         memory_mem_dqs_n,           //                   .mem_dqs_n
    output wire         memory_mem_odt,             //                   .mem_odt
    output wire         memory_mem_dm,              //                   .mem_dm
    input  wire         memory_oct_rzqin            //          
);

wire           asi_ram_clock_sink_clk     ; // asi_ram_clock_sink.clk
wire [9   : 0] asi_ram_io_addr            ; //         asi_ram_io.addr
wire           asi_ram_io_cen             ; //                   .cen
wire [127 : 0] asi_ram_io_wdata           ; //                   .wdata
wire [127 : 0] asi_ram_io_rdata           ; //                   .rdata
wire [15  : 0] asi_ram_io_wen             ; //                   .wen
wire           asi_ram_reset_sink_reset_n ; // asi_ram_reset_sin
wire           cpu_h2f_cold_reset_reset_n ;
wire           clk120m                    ;
wire           clk120m_locked             ;

assign asi_ram_clock_sink_clk = clk120m;     // asi_ram_clock_sink.clk
assign asi_ram_reset_sink_reset_n = clk120m_locked; // asi_ram_reset_sin

my_pll my_pll_inst
(
	.refclk                     ( FPGA_CLK                                        ) ,	// input  refclk_sig
	.rst                        ( !cpu_h2f_cold_reset_reset_n                     ) ,	// input  rst_sig
	.outclk_0                   ( clk120m                                         ) ,	// output  outclk_0_sig
	.locked                     ( clk120m_locked                                  ) 	// output  locked_sig
);

my_ram my_ram_inst
(
	.address                    ( asi_ram_io_addr[9:4]                            ) ,	// input [5:0] address_sig
	.byteena                    ( ~asi_ram_io_wen                                 ) ,	// input [15:0] byteena_sig
	.clock                      ( clk120m                                         ) ,	// input  clock_sig
	.data                       ( asi_ram_io_wdata                                ) ,	// input [127:0] data_sig
	.wren                       ( asi_ram_io_cen==1'b0 && (&asi_ram_io_wen)==1'b0 ) ,	// input  wren_sig
	.q                          ( asi_ram_io_rdata                                ) 	// output [127:0] q_sig
);

sys sys_inst
(
	.asi_ram_clock_sink_clk     ( asi_ram_clock_sink_clk                          ) ,	// input  asi_ram_clock_sink_clk
	.asi_ram_io_addr            ( asi_ram_io_addr                                 ) ,	// output [9:0] asi_ram_io_addr
	.asi_ram_io_cen             ( asi_ram_io_cen                                  ) ,	// output  asi_ram_io_cen
	.asi_ram_io_wdata           ( asi_ram_io_wdata                                ) ,	// output [127:0] asi_ram_io_wdata
	.asi_ram_io_rdata           ( asi_ram_io_rdata                                ) ,	// input [127:0] asi_ram_io_rdata
	.asi_ram_io_wen             ( asi_ram_io_wen                                  ) ,	// output [15:0] asi_ram_io_wen
	.asi_ram_reset_sink_reset_n ( asi_ram_reset_sink_reset_n                      ) ,	// input  asi_ram_reset_sink_reset_n
	.memory_mem_a               ( memory_mem_a                                    ) ,	// output [12:0] memory_mem_a
	.memory_mem_ba              ( memory_mem_ba                                   ) ,	// output [2:0] memory_mem_ba
	.memory_mem_ck              ( memory_mem_ck                                   ) ,	// output  memory_mem_ck
	.memory_mem_ck_n            ( memory_mem_ck_n                                 ) ,	// output  memory_mem_ck_n
	.memory_mem_cke             ( memory_mem_cke                                  ) ,	// output  memory_mem_cke
	.memory_mem_cs_n            ( memory_mem_cs_n                                 ) ,	// output  memory_mem_cs_n
	.memory_mem_ras_n           ( memory_mem_ras_n                                ) ,	// output  memory_mem_ras_n
	.memory_mem_cas_n           ( memory_mem_cas_n                                ) ,	// output  memory_mem_cas_n
	.memory_mem_we_n            ( memory_mem_we_n                                 ) ,	// output  memory_mem_we_n
	.memory_mem_reset_n         ( memory_mem_reset_n                              ) ,	// output  memory_mem_reset_n
	.memory_mem_dq              ( memory_mem_dq                                   ) ,	// inout [7:0] memory_mem_dq
	.memory_mem_dqs             ( memory_mem_dqs                                  ) ,	// inout  memory_mem_dqs
	.memory_mem_dqs_n           ( memory_mem_dqs_n                                ) ,	// inout  memory_mem_dqs_n
	.memory_mem_odt             ( memory_mem_odt                                  ) ,	// output  memory_mem_odt
	.memory_mem_dm              ( memory_mem_dm                                   ) ,	// output  memory_mem_dm
	.memory_oct_rzqin           ( memory_oct_rzqin                                ) , 	// input  memory_oct_rzqin
    .cpu_h2f_cold_reset_reset_n ( cpu_h2f_cold_reset_reset_n                      )     // output cpu_h2f_cold_reset_reset_n
);

endmodule
