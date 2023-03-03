module tb();
    // input
    reg clk;
    reg reset;
    reg [7:0]a;
    reg [7:0]b;
    // output
    wire [7:0]c;

    // Unit Under Test(UUT)
    addr uut(
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        // initialize input
        clk = 0;
        reset = 0;
        a = 0;
        b = 0;
        #10;   // represent over 10 unit time(1 ns/unit)
        reset = 1;
        #10;
        reset = 0;
        #100;
        a = 4;
        b = 7;
        #10;
        a = 8;
        b = 17;

        #100;
        a = 5;
        b = 9;
    end
    always #5 clk = ~clk; // 100 Mhz clock
endmodule