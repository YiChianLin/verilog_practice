module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output reg[7:0] result; 

wire[7:0] mms_4n_cmp1, mms_4n_cmp2; 
wire cmp_bit;
MMS_4num mms_4n_m1(.result(mms_4n_cmp1), .select(select), .number0(number0), .number1(number1), .number2(number2), .number3(number3));
MMS_4num mms_4n_m2(.result(mms_4n_cmp2), .select(select), .number0(number4), .number1(number5), .number2(number6), .number3(number7));

assign cmp_bit = (mms_4n_cmp1 < mms_4n_cmp2);

always @(*) begin	
	case ({select, cmp_bit})
		2'b00: result = mms_4n_cmp1;
		2'b11: result = mms_4n_cmp1;
		default: result = mms_4n_cmp2;
	endcase
end

endmodule
