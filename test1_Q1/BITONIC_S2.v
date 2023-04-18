module BITONIC_S2(  number_in1, number_in2, number_in3, number_in4,
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
BITONIC_DS DS_13(.number_in1(number_in1), .number_in2(number_in3), .number_out1(temp1), .number_out2(temp3));
BITONIC_DS DS_24(.number_in1(number_in2), .number_in2(number_in4), .number_out1(temp2), .number_out2(temp4));
BITONIC_AS AS_57(.number_in1(number_in5), .number_in2(number_in7), .number_out1(temp5), .number_out2(temp7));
BITONIC_AS AS_68(.number_in1(number_in6), .number_in2(number_in8), .number_out1(temp6), .number_out2(temp8));

BITONIC_DS DS_12(.number_in1(temp1), .number_in2(temp2), .number_out1(number_out1), .number_out2(number_out2));
BITONIC_DS DS_34(.number_in1(temp3), .number_in2(temp4), .number_out1(number_out3), .number_out2(number_out4));
BITONIC_AS AS_56(.number_in1(temp5), .number_in2(temp6), .number_out1(number_out5), .number_out2(number_out6));
BITONIC_AS AS_78(.number_in1(temp7), .number_in2(temp8), .number_out1(number_out7), .number_out2(number_out8));

endmodule