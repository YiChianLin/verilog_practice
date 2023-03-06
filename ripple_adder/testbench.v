module stimulus;
    reg clk;
    reg reset;
    wire [3:0]q;

    // UUT
    ripple_carry_counter r1(q, clk, reset);

    initial 
        clk = 1'b0; // initial the clk = 0
    always
        #5 clk = ~clk; // set the 5 time unit reverse

    initial begin
        reset = 1'b1;
        #15 reset = 1'b0;
        #180 reset = 1'b1;
        #10 reset = 1'b0;
        #20 $finish;
    end

    // display
    initial
        $monitor($time, " Output q = %d", q);

endmodule