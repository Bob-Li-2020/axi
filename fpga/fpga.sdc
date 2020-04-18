## Generated SDC file "fpga.sdc"

## Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 15.1.0 Build 185 10/21/2015 SJ Standard Edition"

## DATE    "Fri Apr 17 17:06:34 2020"

##
## DEVICE  "5CSEBA6U23I7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {FPGA_CLK} -period 20.000 -waveform { 0.000 10.000 } [get_ports {FPGA_CLK}]
create_clock -name {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk} -period 3.333 -waveform { 2.499 4.166 } [get_registers {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk}]
create_clock -name {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk} -period 3.333 -waveform { 0.000 1.666 } [get_registers {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk}]
create_clock -name {memory_mem_dqs_IN} -period 3.333 -waveform { 0.000 1.667 } [get_ports {memory_mem_dqs}] -add
create_clock -name {sys_inst|cpu|fpga_interfaces|clocks_resets|h2f_user0_clk} -period 10.000 -waveform { 0.000 5.000 } [get_pins -compatibility_mode {*|fpga_interfaces|clocks_resets|h2f_user0_clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks
create_generated_clock -name {memory_mem_ck} -source [get_registers {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk}] -master_clock {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk} [get_ports {memory_mem_ck}] 
create_generated_clock -name {memory_mem_ck_n} -source [get_registers {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk}] -master_clock {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk} -invert [get_ports {memory_mem_ck_n}] 
create_generated_clock -name {memory_mem_dqs_OUT} -source [get_registers {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk}] -master_clock {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk} [get_ports {memory_mem_dqs}] -add
create_generated_clock -name {memory_mem_dqs_n_OUT} -source [get_registers {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk}] -master_clock {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk} [get_ports {memory_mem_dqs_n}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_OUT}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_OUT}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_OUT}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_OUT}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_OUT}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_OUT}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_OUT}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_OUT}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_n_OUT}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_n_OUT}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_n_OUT}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_n_OUT}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_dqs_IN}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_dqs_IN}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_ck_n}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_ck_n}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_ck}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_ck}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {FPGA_CLK}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {FPGA_CLK}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_dqs_IN}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_dqs_IN}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_ck_n}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_ck_n}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {memory_mem_ck}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {memory_mem_ck}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -rise_to [get_clocks {FPGA_CLK}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_dqs_IN}] -fall_to [get_clocks {FPGA_CLK}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck_n}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck_n}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck_n}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck_n}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck_n}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck_n}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck_n}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck_n}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck_n}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck_n}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck_n}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck_n}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {memory_mem_ck}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|pll_write_clk_dq_write_clk}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -rise_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_dqs_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_dqs_n_OUT}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_ck_n}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -rise_to [get_clocks {memory_mem_ck}]  0.226  
set_clock_uncertainty -fall_from [get_clocks {FPGA_CLK}] -fall_to [get_clocks {memory_mem_ck}]  0.226  
derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[0]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[0]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[1]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[1]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[2]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[2]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[3]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[3]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[4]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[4]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[5]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[5]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[6]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[6]}]
set_input_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_IN}]  0.153 [get_ports {memory_mem_dq[7]}]
set_input_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_IN}]  -0.416 [get_ports {memory_mem_dq[7]}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[0]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[0]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[1]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[1]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[2]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[2]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[3]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[3]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[4]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[4]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[5]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[5]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[6]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[6]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[7]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[7]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[8]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[8]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[9]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[9]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[10]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[10]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[11]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[11]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_a[12]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_a[12]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_ba[0]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_ba[0]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_ba[1]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_ba[1]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_ba[2]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_ba[2]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_cas_n}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_cas_n}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_cke}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_cke}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_cs_n}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_cs_n}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dm}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dm}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dm}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dm}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[0]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[0]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[0]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[0]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[1]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[1]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[1]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[1]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[2]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[2]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[2]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[2]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[3]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[3]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[3]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[3]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[4]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[4]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[4]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[4]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[5]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[5]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[5]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[5]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[6]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[6]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[6]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[6]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_OUT}]  0.386 [get_ports {memory_mem_dq[7]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_OUT}]  -0.382 [get_ports {memory_mem_dq[7]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_dqs_n_OUT}]  0.386 [get_ports {memory_mem_dq[7]}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_dqs_n_OUT}]  -0.382 [get_ports {memory_mem_dq[7]}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.301 [get_ports {memory_mem_dqs}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.032 [get_ports {memory_mem_dqs}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_odt}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_odt}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_ras_n}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_ras_n}]
set_output_delay -add_delay -max -clock [get_clocks {memory_mem_ck}]  2.037 [get_ports {memory_mem_we_n}]
set_output_delay -add_delay -min -clock [get_clocks {memory_mem_ck}]  1.297 [get_ports {memory_mem_we_n}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -physically_exclusive -group [get_clocks {memory_mem_dqs_IN}] -group [get_clocks {memory_mem_dqs_OUT memory_mem_dqs_n_OUT}] 
set_clock_groups -exclusive -group [get_clocks {my_pll_inst|my_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -group [get_clocks {sys_inst|cpu|fpga_interfaces|clocks_resets|h2f_user0_clk}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path  -fall_from  [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  -to  [get_clocks {memory_mem_ck}]
set_false_path  -from  [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  -to  [get_clocks {*_IN}]
set_false_path -to [get_pins -nocase -compatibility_mode {*|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain*|clrn}]
set_false_path -fall_from [get_clocks {sys:sys_inst|sys_cpu:cpu|sys_cpu_hps_io:hps_io|sys_cpu_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -to [get_ports {{memory_mem_a[0]} {memory_mem_a[10]} {memory_mem_a[11]} {memory_mem_a[12]} {memory_mem_a[1]} {memory_mem_a[2]} {memory_mem_a[3]} {memory_mem_a[4]} {memory_mem_a[5]} {memory_mem_a[6]} {memory_mem_a[7]} {memory_mem_a[8]} {memory_mem_a[9]} {memory_mem_ba[0]} {memory_mem_ba[1]} {memory_mem_ba[2]} memory_mem_cas_n memory_mem_cke memory_mem_cs_n memory_mem_odt memory_mem_ras_n memory_mem_we_n}]
set_false_path -to [get_ports {memory_mem_dqs_n}]
set_false_path -to [get_ports {memory_mem_ck}]
set_false_path -to [get_ports {memory_mem_ck_n}]
set_false_path -to [get_ports {memory_mem_reset_n}]
set_false_path -from [get_keepers {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_clocks {memory_mem_dqs_OUT}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -setup -end -to [get_registers {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*uio_pads|*uaddr_cmd_pads|*clock_gen[*].umem_ck_pad|*}] 4
set_multicycle_path -hold -end -to [get_registers {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*uio_pads|*uaddr_cmd_pads|*clock_gen[*].umem_ck_pad|*}] 4


#**************************************************************
# Set Maximum Delay
#**************************************************************

set_max_delay -from [get_ports {memory_mem_dq[0]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[1]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[2]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[3]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[4]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[5]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[6]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000
set_max_delay -from [get_ports {memory_mem_dq[7]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] 0.000


#**************************************************************
# Set Minimum Delay
#**************************************************************

set_min_delay -from [get_ports {memory_mem_dq[0]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[1]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[2]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[3]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[4]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[5]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[6]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667
set_min_delay -from [get_ports {memory_mem_dq[7]}] -to [get_keepers {{*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].capture_reg~DFFLO} {*:sys_inst|*:cpu|*:hps_io|*:border|*:hps_sdram_inst|*:p0|*:umemphy|*:uio_pads|*:dq_ddio[*].ubidir_dq_dqs|*:altdq_dqs2_inst|*input_path_gen[*].aligned_input[*]}}] -1.667


#**************************************************************
# Set Input Transition
#**************************************************************

