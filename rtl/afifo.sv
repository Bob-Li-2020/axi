// Author: LiBing
// Date: 2020/6/15
// Description: asynchronous fifo

module afifo
#(
    AW=4,
    DW=8 
)(
    input  logic            wreset_n ,
    input  logic            rreset_n ,
    input  logic            wclk     ,
    input  logic            rclk     ,
    input  logic            we       , // write enable
    input  logic            re       , // read enable
    output logic            wfull    , // write full
    output logic            rempty   , // read empty
    output logic [AW   : 0] wcnt     , // counter of data in fifo, write-side
    output logic [AW   : 0] rcnt     , // counter of data in fifo, read-side
    input  logic [DW-1 : 0] d        , // write data
    output logic [DW-1 : 0] q          // read data
);

timeprecision 1ps;
timeunit 1ns;

logic [AW-1 : 0] waddr, raddr;
logic [AW   : 0] wbin, wbin_nxt, wgray, wgray_nxt, wq1_rgray, wq2_rgray, wcnt_nxt;
logic [AW   : 0] rbin, rbin_nxt, rgray, rgray_nxt, rq1_wgray, rq2_wgray, rcnt_nxt;
logic            wfull_nxt  ;
logic            rempty_nxt ;
logic [DW-1 : 0] mem[2**AW] ;

assign q          = mem[raddr]         ;
assign waddr      = wbin[AW-1:0]       ;
assign raddr      = rbin[AW-1:0]       ;
assign wbin_nxt   = wbin+(we & !wfull) ;
assign rbin_nxt   = rbin+(re & !rempty);
assign wgray_nxt  = (wbin_nxt>>1)^wbin_nxt;
assign rgray_nxt  = (rbin_nxt>>1)^rbin_nxt;
assign wfull_nxt  = wgray_nxt=={ ~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0] };
assign rempty_nxt = rgray_nxt==rq2_wgray;
assign wcnt_nxt   = wbin_nxt-GRAY2BIN(wq2_rgray);
assign rcnt_nxt   = GRAY2BIN(rq2_wgray)-rbin_nxt;

always_ff @(posedge wclk or negedge wreset_n)
    if(!wreset_n)
        { wbin, wgray } <= '0;
    else
        { wbin, wgray } <= { wbin_nxt, wgray_nxt };

always_ff @(posedge wclk or negedge wreset_n)
    if(!wreset_n)
        { wq2_rgray, wq1_rgray } <= '0;
    else
        { wq2_rgray, wq1_rgray } <= { wq1_rgray, rgray };

always_ff @(posedge rclk or negedge rreset_n)
    if(!rreset_n)
        { rbin, rgray } <= '0;
    else
        { rbin, rgray } <= { rbin_nxt, rgray_nxt };

always_ff @(posedge rclk or negedge rreset_n)
    if(!rreset_n)
        { rq2_wgray, rq1_wgray } <= '0;
    else
        { rq2_wgray, rq1_wgray } <= { rq1_wgray, wgray };

always_ff @(posedge wclk)
    if(we && !wfull)
        mem[waddr] <= d;

always_ff @(posedge wclk or negedge wreset_n)
    if(!wreset_n) 
        wfull  <= 1'b0;
    else 
        wfull  <= wfull_nxt;

always_ff @(posedge wclk or negedge wreset_n)
    if(!wreset_n)
        wcnt <= 0;
    else
        wcnt <= wcnt_nxt;

always_ff @(posedge rclk or negedge rreset_n)
    if(!rreset_n)
        rempty <= 1'b1;
    else
        rempty <= rempty_nxt;

always_ff @(posedge rclk or negedge rreset_n)
    if(!rreset_n)
        rcnt <= 0;
    else
        rcnt <= rcnt_nxt;

//functions
function logic [AW:0] GRAY2BIN(input logic [AW:0] gray);
    logic [AW : 0] bin ;
    bin[AW] = gray[AW];
    for(int i=AW-1;i>=0;i=i-1)
        bin[i] = bin[i+1]^gray[i];
    return bin;
endfunction: GRAY2BIN

// ********* for verification *************
// assertions
//always_comb 
//    assert(wcnt<=(1<<AW)) else begin
//        $error("%0t: wcnt=%0d", $realtime, wcnt);
//        $finish;
//    end
//
//always_comb 
//    assert(rcnt<=(1<<AW)) else begin
//        $error("%0t: rcnt=%0d", $realtime, rcnt);
//        $finish;
//    end
//
//always_comb 
//    if(rcnt==0)
//        assert(rempty) else begin
//            $error("%0t: rcnt=%0d; rempty=%b.", $realtime, rcnt, rempty);
//            $finish;
//        end
//
//always_comb 
//    if(rempty)
//        assert(rcnt==0) else begin
//            $error("%0t: rcnt=%0d; rempty=%b.", $realtime, rcnt, rempty);
//            $finish;
//        end
//
//always_comb begin
//    if(wfull)
//        assert(wcnt==(1<<AW)) else begin
//            $error("%0t: wcnt=%0d; wfull=%b.", $realtime, wcnt, wfull);
//            $finish;
//        end
//end
//
//always_comb begin
//    if(wcnt==(1<<AW))
//        assert(wfull) else begin
//            $error("%0t: wcnt=%0d; wfull=%b.", $realtime, wcnt, wfull);
//            $finish;
//        end
//end
endmodule


