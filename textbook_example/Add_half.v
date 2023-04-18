// 1 bit
module Add_half(sum, c_out, a, b);
input a, b;
output sum, c_out;
assign {c_out, sum} = a + b;
endmodule