module MMS_4num(result, select, number0, number1, number2, number3);

input  		 select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output reg[7:0] result; 

reg[7:0] cmp1, cmp2; 

always @(select, number0, number1) begin
	case ({select, (number0 < number1)})
		2'b00 : cmp1 = number0;
		2'b11 : cmp1 = number0;
		default: cmp1 = number1;
	endcase
end
always @(select, number2, number3) begin
	case ({select, (number2 < number3)})
		2'b00 : cmp2 = number2;
		2'b11 : cmp2 = number2;
		default: cmp2 = number3;
	endcase
end

always @(cmp1, cmp2) begin
	case ({select, (cmp1 < cmp2)})
		2'b00 : result = cmp1;
		2'b11 : result = cmp1;
		default: result = cmp2;
	endcase
end
endmodule
