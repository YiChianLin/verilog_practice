module MMS_4num(result, select, number0, number1, number2, number3);

input  		 select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result; 

reg[7:0] cmp1, cmp2, result; 

always @(select or number0 or number1 or number2 or number3) begin
	if (select) begin
		cmp1 = (number0 < number1) ? number0 : number1;
		cmp2 = (number2 < number3) ? number2 : number3;
		result = (cmp1 < cmp2) ? cmp1 : cmp2;
	end
	else begin
		cmp1 = (number0 < number1) ? number1 : number0;
		cmp2 = (number2 < number3) ? number3 : number2;
		result = (cmp1 < cmp2) ? cmp2 : cmp1;
	end
end
endmodule
