program automatic reset_gen #(
    RESET0_P = 10.1,
    RESET1_P = 11.2
)(
    input  bit stop,
    output bit rst0,
    output bit rst1
);

timeprecision 1ps;
timeunit 1ns;

task generate_a_reset(ref bit rst, input int P);
    // P: reset initial phase
    // rst: High-Active reset
    rst = 1'b1;
    #P;
    rst = 1'b0;
    wait(stop);
    #P;
    rst = 1'b1;
endtask

initial begin
    fork
        generate_a_reset(rst0, RESET0_P);
        generate_a_reset(rst1, RESET1_P);
    join
end

endprogram: reset_gen
