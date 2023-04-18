module BITONIC_S1(  number_in1, number_in2, number_in3, number_in4,
                    number_in5, number_in6, number_in7, number_in8,
                    number_out1, number_out2, number_out3, number_out4,
                    number_out5, number_out6, number_out7, number_out8);

input  [7:0] number_in1;
input  [7:0] number_in2;
input  [7:0] number_in3;
input  [7:0] number_in4;
input  [7:0] number_in5;
input  [7:0] number_in6;
input  [7:0] number_in7;
input  [7:0] number_in8;

output  [7:0] number_out1;
output  [7:0] number_out2;
output  [7:0] number_out3;
output  [7:0] number_out4;
output  [7:0] number_out5;
output  [7:0] number_out6;
output  [7:0] number_out7;
output  [7:0] number_out8;

wire [7:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8;
BITONIC_DS DS_12(.number_in1(number_in1), .number_in2(number_in2), .number_out1(temp1), .number_out2(temp2));
BITONIC_AS AS_34(.number_in1(number_in3), .number_in2(number_in4), .number_out1(temp3), .number_out2(temp4));
BITONIC_DS DS_56(.number_in1(number_in5), .number_in2(number_in6), .number_out1(temp5), .number_out2(temp6));
BITONIC_AS AS_78(.number_in1(number_in7), .number_in2(number_in8), .number_out1(temp7), .number_out2(temp8));

assign number_out1 = temp1;
assign number_out2 = temp2;
assign number_out3 = temp3;
assign number_out4 = temp4;
assign number_out5 = temp5;
assign number_out6 = temp6;
assign number_out7 = temp7;
assign number_out8 = temp8;

endmodule