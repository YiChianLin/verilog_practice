module Add_full(sum, c_out, a, b, c_in);
input a, b, c_in;
output sum, c_out;
wire w1, w2, w3;
Add_half M1(w1, w2, a, b);
Add_half M2(sum, w3, c_in, w1);
or (c_out, w2, w3);
endmodule

module Add_half(sum, c_out, a, b);
input a, b;
output sum, c_out;
assign {c_out, sum} = a + b;
endmodule