module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;

/* State describle
** DATA_IN : modify the input ASCII data to 0~15 for number 0~15 and 16~20
**           for operator '('、')'、'*'、'+'、'-'           
**
*/

// state define
reg [1:0] Currentstate, Nextstate;
localparam DATA_IN = 2'd0;
localparam CHECK_DATA = 2'd1;
localparam CHECK_STACK_EMPTY = 2'd2;
localparam CALCULATE= 2'd3;

// variable 
reg [4:0] i; // for-loop
reg [6:0] data_arr[15:0];
reg [3:0] data_arr_idx;
reg [6:0] stack[15:0];  // first bit 1 present the operator
reg [6:0] postfix_result[15:0]; 
reg [3:0] postfix_idx;
reg [3:0] stack_index;
reg [3:0] pop_time, data_num;

wire [3:0] stack_index_minus_one = stack_index - 4'd1;
wire [3:0] stack_index_minus_two = stack_index - 4'd2;

// sequential circuit
always @(posedge clk) begin
    if (rst) begin
		Currentstate <= DATA_IN;
	end
	else
		Currentstate <= Nextstate;
end

// nextstate conbination
always @(*) begin
    case (Currentstate) 
        DATA_IN : begin
            if (ascii_in == 8'b00111101) begin
                Nextstate <= CHECK_DATA;
            end
            else begin
                Nextstate <= DATA_IN;
            end
        end
        CHECK_DATA : begin
            if ((data_arr_idx + 1) == data_num) begin 
                Nextstate <= CHECK_STACK_EMPTY; 
            end
            else begin
                Nextstate <= CHECK_DATA;
            end
        end

        CHECK_STACK_EMPTY : begin      
            if (stack_index > 4'b0) begin
                Nextstate <= CHECK_STACK_EMPTY;
            end
            else begin
                Nextstate <= CALCULATE;
            end
        end

        CALCULATE : begin       
            if ((data_arr_idx < pop_time) | (valid == 0)) begin
                Nextstate <= CALCULATE;
            end
            else begin
                Nextstate <= DATA_IN;
            end
        end

        default : begin Nextstate <= DATA_IN; end
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i = 0; i < 5'b1_0000 ; i = i + 1) begin 
            data_arr[i] <= 7'b000_0000; 
            stack[i] <= 7'b000_0000;
            postfix_result[i] <= 7'b000_0000;
        end

        stack_index <= 4'b0000;
        postfix_idx <= 4'b0000;
        data_arr_idx <= 4'b0000;
        pop_time <= 4'b0000;
        data_num <= 4'b0000;
    end
    else begin 
        case (Currentstate)
            DATA_IN : begin 
                valid <= 1'b0;
                if (ascii_in[6:0] == 7'b011_1101) begin 
                    data_arr_idx <= 0;
                end 
                else  begin 
                    data_arr_idx <= data_arr_idx + 1;
                    pop_time <= pop_time + 1;
                    data_num <= data_num + 1;
                end

                case (ascii_in[6:0])
                    7'b011_1101 : begin 
                        // '='
                        data_arr_idx <= 0; 
                    end  
                    7'b010_1000 : begin 
                        // '('
                        data_arr[data_arr_idx] <= 7'b001_0000;
                    end
                    7'b010_1001 : begin 
                        // ')'
                        data_arr[data_arr_idx] <= 7'b001_0001;
                    end
                    7'b010_1010 : begin 
                        // '*'
                        data_arr[data_arr_idx] <= 7'b001_1000;
                    end
                    7'b010_1011 : begin 
                        // '+'
                        data_arr[data_arr_idx] <= 7'b001_0100;
                    end
                    7'b010_1101 : begin 
                        // '-'
                        data_arr[data_arr_idx] <= 7'b001_0101;
                    end
                    default: begin 
                        // number 0~15
                        data_arr[data_arr_idx] <= {3'b000, (ascii_in[6] & 1'b1), 2'b00, (ascii_in[4] ^ 1'b1)} + ascii_in[3:0];
                    end
                endcase
            end
            CHECK_DATA : begin
                // pop directly or pop from stack
                if ((data_arr[data_arr_idx] < 7'b001_0000)) begin
                    postfix_result[postfix_idx] <= data_arr[data_arr_idx];
                    postfix_idx <= postfix_idx + 1;
                    data_arr_idx <= data_arr_idx + 1;
                end
                else if ((stack_index == 4'b0) | data_arr[data_arr_idx] == 7'b001_0000 | ((data_arr[data_arr_idx] & 7'b001_1100) > (stack[stack_index_minus_one] & 7'b001_1100))) begin
                    stack[stack_index] <= data_arr[data_arr_idx];
                    stack_index <= stack_index + 1;
                    data_arr_idx <= data_arr_idx + 1;
                end
                else if (stack[stack_index_minus_one] == 7'b001_0000) begin
                    stack_index <= stack_index - 1;
                    data_arr_idx <= data_arr_idx + 1;
                    pop_time <= pop_time - 2;  // () - 2
                end
                else begin
                    postfix_result[postfix_idx] <= stack[stack_index_minus_one];
                    stack_index <= stack_index - 1;
                    postfix_idx <= postfix_idx + 1;
                end
            end
            
            CHECK_STACK_EMPTY : begin
                data_arr_idx <= 0;
                if (stack[stack_index_minus_one] != 7'b001_0000) begin
                    postfix_idx <= postfix_idx + 1;
                end
                
                if (stack_index > 4'b0) begin
                    postfix_result[postfix_idx] <= stack[stack_index_minus_one];
                    stack_index <= stack_index - 1;
                end 
            end

            CALCULATE : begin
                // number -> push // operator -> pop and calculate
                if (valid == 0) begin
                    if(data_arr_idx < pop_time) begin
                        data_arr_idx <= data_arr_idx + 1;
                        case (postfix_result[data_arr_idx])
                            7'b001_1000 : begin
                                stack[stack_index_minus_two] <= stack[stack_index_minus_two] * stack[stack_index_minus_one];
                                stack_index <= stack_index - 1;
                            end
                            7'b001_0100 : begin
                                stack[stack_index_minus_two] <= stack[stack_index_minus_two] + stack[stack_index_minus_one];
                                stack_index <= stack_index - 1;
                            end
                            7'b001_0101 : begin
                                stack[stack_index_minus_two] <= stack[stack_index_minus_two] - stack[stack_index_minus_one];
                                stack_index <= stack_index - 1;
                            end
                            default: begin  
                                stack[stack_index] <= postfix_result[data_arr_idx];
                                stack_index <= stack_index + 1;
                            end
                        endcase
                    end
                    else begin
                        valid <= 1;
                        result <= stack[0];
                    end
                end
                else begin
                    for(i = 0; i < 5'b1_0000; i = i + 1) begin 
                        data_arr[i] <= 7'b000_0000; 
                        stack[i] <= 7'b000_0000;
                        postfix_result[i] <= 7'b000_0000;
                    end
                    
                    // array index
                    stack_index <= 4'b0000;
                    postfix_idx <= 4'b0000;
                    data_arr_idx <= 4'b0000;
                    // some counter
                    pop_time <= 4'b0000;
                    data_num <= 4'b0000;
                end
            end

            default : begin end // do nothing
        endcase
    end

end

endmodule