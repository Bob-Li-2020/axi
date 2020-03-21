program automatic clk_gen #(
    CLK0_T = 2.0, // clk0 period(ns)
    CLK0_P = 0.2, // clk0 initial phase(ns)
    CLK0_J = 0.1, // clk0 maximum jitter(ns)
    CLK1_T = 2.0, // clk1 period(ns)
    CLK1_P = 0.4, // clk1 initial phase(ns)
    CLK1_J = 0.1  // clk1 maximum jitter(ns)
)(
    input  bit stop , // Active-High
    output bit clk0 ,
    output bit clk1
);

timeprecision 1ps;
timeunit 1ns;

task generate_a_clock(ref bit clk, input real T, P, J);
    int  clkj_int ; // clock jitter integer
    real clkj_real; // clock jitter real
    bit  clkj_sign; // clock jitter sign bit
    real clkj_t   ; // clock after jitter
    clk = 1'b0;
    #P;
    while(!stop) begin
        clkj_int = $urandom_range(0, J*1000);
        clkj_real = real'(clkj_int)/1000;
        clkj_sign = $urandom_range(0,1);
        if(clkj_sign) 
            clkj_t = T/2+clkj_real;
        else
            clkj_t = T/2-clkj_real;
        #clkj_t;
        //$display("clkj_int  = %0d", clkj_int   );
        //$display("clkj_real = %f" , clkj_real  );
        //$display("clkj_sign = %b" , clkj_sign  );
        //$display("clkj_t    = %f" , clkj_t     );
        //$display;
        clk++;
    end
endtask: generate_a_clock

initial begin
    fork
        generate_a_clock(clk0, CLK0_T, CLK0_P, CLK0_J);
        generate_a_clock(clk1, CLK1_T, CLK1_P, CLK1_J);
    join
end

endprogram
