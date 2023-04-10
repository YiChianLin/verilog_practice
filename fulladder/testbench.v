module tb_fulladd;
// 1. Declare tb variable
reg [3:0] a;
reg [3:0] b;
reg c_in;
wire c_out;
wire [3:0] sum;
integer i, seed;

// 2.Instantiate the design and connect to tb variable
fulladder FA1(.a(a), .b(b), .c_in(c_in), .c_out(c_out), .sum(sum));

// 3. Provide stimulus to test the design
initial begin
    a <= 0;
    b <= 0;
    c_in <= 0;
    seed = 1;

    // With error using monitor twice
    $monitor("a = 0x%0d, b = 0x%0d, c_in = 0x%0d, c_out = 0x%0d, sum = 0x%0d, result = %d", a, b, c_in, c_out, sum, {c_out, sum});
    
    // Use a for loop
    for (i = 0; i < 5; i = i + 1) begin
        #10 a <= $random(seed);
            b <= $random(seed);
            c_in <= $random(seed);       
    end
end
endmodule