module addr(
    input clk,
    input reset,
    input [7:0]a,
    input [7:0]b,
    output reg [7:0]c
);
    always @(posedge clk) begin
        if (reset)
            c <= 0;
        else
            c <= a + b;
    end

endmodule