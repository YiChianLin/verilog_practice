module BITONIC_S3(  number_in1, number_in2, number_in3, number_in4,
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

wire [7:0] s1_tmp1, s1_tmp2, s1_tmp3, s1_tmp4, s1_tmp5, s1_tmp6, s1_tmp7, s1_tmp8;
BITONIC_DS DS_15(.number_in1(number_in1), .number_in2(number_in5), .number_out1(s1_tmp1), .number_out2(s1_tmp5));
BITONIC_DS DS_26(.number_in1(number_in2), .number_in2(number_in6), .number_out1(s1_tmp2), .number_out2(s1_tmp6));
BITONIC_DS DS_37(.number_in1(number_in3), .number_in2(number_in7), .number_out1(s1_tmp3), .number_out2(s1_tmp7));
BITONIC_DS DS_48(.number_in1(number_in4), .number_in2(number_in8), .number_out1(s1_tmp4), .number_out2(s1_tmp8));

wire [7:0] s2_tmp1, s2_tmp2, s2_tmp3, s2_tmp4, s2_tmp5, s2_tmp6, s2_tmp7, s2_tmp8;
BITONIC_DS DS_13(.number_in1(s1_tmp1), .number_in2(s1_tmp3), .number_out1(s2_tmp1), .number_out2(s2_tmp3));
BITONIC_DS DS_24(.number_in1(s1_tmp2), .number_in2(s1_tmp4), .number_out1(s2_tmp2), .number_out2(s2_tmp4));
BITONIC_DS DS_57(.number_in1(s1_tmp5), .number_in2(s1_tmp7), .number_out1(s2_tmp5), .number_out2(s2_tmp7));
BITONIC_DS DS_68(.number_in1(s1_tmp6), .number_in2(s1_tmp8), .number_out1(s2_tmp6), .number_out2(s2_tmp8));

BITONIC_DS DS_12(.number_in1(s2_tmp1), .number_in2(s2_tmp2), .number_out1(number_out1), .number_out2(number_out2));
BITONIC_DS DS_34(.number_in1(s2_tmp3), .number_in2(s2_tmp4), .number_out1(number_out3), .number_out2(number_out4));
BITONIC_DS DS_56(.number_in1(s2_tmp5), .number_in2(s2_tmp6), .number_out1(number_out5), .number_out2(number_out6));
BITONIC_DS DS_78(.number_in1(s2_tmp7), .number_in2(s2_tmp8), .number_out1(number_out7), .number_out2(number_out8));

endmodule
