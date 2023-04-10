/* Method 1 */
module fulladder(
    input [3:0]a,
    input [3:0]b,
    input c_in,
    output c_out,
    output [3:0]sum
);

assign {c_out, sum} = a + b + c_in;
endmodule

/* Method 2 */
// module fulladder(
//     input [3:0]a,
//     input [3:0]b,
//     input c_in,
//     output c_out,
//     output [3:0]sum
// );

// always @(a or b or c_in) begin
//     {c_out, sum} = a + b +c_in;
// end
// endmodule