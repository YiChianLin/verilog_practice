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
 * DATA_IN:modify the input ASCII data to 0~15 for number 0~15 and store 
 *           the operator data '('、')'、'*'、'+'、'-' until encounter "="           
 * CHECK_DATA:check the data precedence to pop or push each other
 * CHECK_STACK_EMPTY:if check all input data, check the stack is empty
 * CALCULATE:use postfix result to calculate, when complete the process
 * output the result and reset
 * RESET:reset the signal
 */

// state define
reg [2:0] Currentstate, Nextstate;
localparam DATA_IN = 3'd0;
localparam CHECK_DATA = 3'd1;
localparam CHECK_STACK_EMPTY = 3'd2;
localparam CALCULATE= 3'd3;
localparam RESET= 3'd4;

// variable 
reg [4:0] i; // for-loop
reg [6:0] data_arr[15:0];  // the input data array and store the postfix result
reg [3:0] data_arr_idx;    
reg [6:0] stack[7:0];     // stack for infix to postfix and calculate
reg [3:0] postfix_idx;     // the index for postfix to data array
reg [2:0] stack_index;
reg [3:0] pop_time, data_num;   // calculate the calculate time and the total data number(if encounter the parentheses)

wire [2:0] stack_index_minus_one = stack_index - 4'd1;
wire [2:0] stack_index_minus_two = stack_index - 4'd2;

// sequential circuit
always @(posedge clk) begin
    if (rst) begin
		Currentstate <= DATA_IN;
	end
	else begin
        Currentstate <= Nextstate;
    end
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
            // if completely run all data
            if ((data_arr_idx + 1) == data_num) begin 
                Nextstate <= CHECK_STACK_EMPTY; 
            end
            else begin
                Nextstate <= CHECK_DATA;
            end
        end

        // pop all the stack data
        CHECK_STACK_EMPTY : begin      
            if (stack_index > 3'b0) begin
                Nextstate <= CHECK_STACK_EMPTY;
            end
            else begin
                Nextstate <= CALCULATE;
            end
        end

        // calculate the result
        CALCULATE : begin       
            if ((data_arr_idx < pop_time)) begin
                Nextstate <= CALCULATE;
            end
            else begin
                Nextstate <= RESET;
            end
        end

        RESET : begin Nextstate <= DATA_IN; end

        default : begin Nextstate <= DATA_IN; end
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        // reset
        for(i = 0; i < 5'b1_0000 ; i = i + 1) begin 
            data_arr[i] <= 7'b000_0000; 
        end

        for(i = 0; i < 4'b1000 ; i = i + 1) begin 
            stack[i] <= 7'b000_0000;
        end

        stack_index <= 3'b000;
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
                else if(ascii_in[6:0] < 7'b011_0000) begin
                    // store the original data for operator
                    data_arr[data_arr_idx] <= ascii_in[6:0];
                    data_arr_idx <= data_arr_idx + 1;
                    pop_time <= pop_time + 1;
                    data_num <= data_num + 1;
                end
                else begin
                    // store the 0~15 number, a~f(10~15) must add 9(4'b1001) to transfer, 0~9 add 0(4'b0000),
                    // so using ascii[6] and ascii[4] two different bits to distribute 9 and 0 
                    data_arr[data_arr_idx] <= {3'b000, (ascii_in[6] & 1'b1), 2'b00, (ascii_in[4] ^ 1'b1)} + ascii_in[3:0];
                    data_arr_idx <= data_arr_idx + 1;
                    pop_time <= pop_time + 1;
                    data_num <= data_num + 1;
                end       
            end

            CHECK_DATA : begin
                // pop the number
                if ((data_arr[data_arr_idx] < 7'b001_0000)) begin
                    data_arr[postfix_idx] <= data_arr[data_arr_idx];
                    postfix_idx <= postfix_idx + 1;
                    data_arr_idx <= data_arr_idx + 1;
                end
                else if ((stack_index == 3'b0) | data_arr[data_arr_idx][2:0] == 3'b000 | 
                ({data_arr[data_arr_idx][2:0] == 3'b010, data_arr[data_arr_idx][2:0] > 3'b001} > 
                 {stack[stack_index_minus_one][2:0] == 3'b010, stack[stack_index_minus_one][2:0] > 3'b001})) begin
                    // In this stage the data just remain '(' ')' '*' '+' '-' decide the push situation
                    // 1. if stack is empty push the data in stack
                    // 2. if the data is '(' push
                    // 3. check the precedence whether it is larger than top stack
                    // -> the method to decide the precedence:
                    //    consider the data 3-bit:
                    //    -> if equal '*' and if large than ')' number
                    // so we got the number of precedence
                    // '*'      -> {1, 1}
                    // '+', '-' -> {0, 1}
                    // '(', ')' -> {0, 0} 
                    stack[stack_index] <= data_arr[data_arr_idx];
                    stack_index <= stack_index + 1;
                    data_arr_idx <= data_arr_idx + 1;
                end
                else if (stack[stack_index_minus_one] == 7'b010_1000) begin
                    // according to previous if-else, need to pop the data from stack, but if encounter the '(' just skip 
                    stack_index <= stack_index - 1;
                    data_arr_idx <= data_arr_idx + 1;
                    pop_time <= pop_time - 2;  // () - 2
                end
                else begin
                    // pop the data from stack
                    data_arr[postfix_idx] <= stack[stack_index_minus_one];
                    stack_index <= stack_index - 1;
                    postfix_idx <= postfix_idx + 1;
                end
            end
            
            CHECK_STACK_EMPTY : begin
                data_arr_idx <= 0;
                // if not encounter the '(' just pop the data from stack
                if (stack[stack_index_minus_one] != 7'b010_1000) begin
                    postfix_idx <= postfix_idx + 1;
                end
                else if (stack[stack_index_minus_one] == 7'b010_1000) begin
                // if encounter the '(' reduce the calculate time
                    pop_time <= pop_time - 2;
                end
                
                // check the stack whether empty
                if (stack_index > 3'b0) begin
                    data_arr[postfix_idx] <= stack[stack_index_minus_one];
                    stack_index <= stack_index - 1;
                end   
            end

            CALCULATE : begin
            // number -> push // operator -> pop and calculate
            // if (valid == 0) begin
                if(data_arr_idx < pop_time) begin
                    data_arr_idx <= data_arr_idx + 1;
                    case (data_arr[data_arr_idx])
                        // operator '*'
                        7'b010_1010 : begin
                            stack[stack_index_minus_two] <= stack[stack_index_minus_two] * stack[stack_index_minus_one];
                            stack_index <= stack_index - 1;
                        end
                        // operator '+'
                        7'b010_1011 : begin
                            stack[stack_index_minus_two] <= stack[stack_index_minus_two] + stack[stack_index_minus_one];
                            stack_index <= stack_index - 1;
                        end
                        // operator '-'
                        7'b010_1101 : begin
                            stack[stack_index_minus_two] <= stack[stack_index_minus_two] - stack[stack_index_minus_one];
                            stack_index <= stack_index - 1;
                        end
                        default: begin  
                            // if the data if number push in the stack
                            stack[stack_index] <= data_arr[data_arr_idx];
                            stack_index <= stack_index + 1;
                        end
                    endcase
                end
                else begin
                    // output the result
                    valid <= 1;
                    result <= stack[0];
                end
            end

            RESET : begin
                // reset 
                for(i = 0; i < 5'b1_0000; i = i + 1) begin 
                    data_arr[i] <= 7'b000_0000; 
                end
                    
                for(i = 0; i < 4'b1000; i = i + 1) begin 
                    stack[i] <= 7'b000_0000;
                end
                // array index
                stack_index <= 3'b000;
                postfix_idx <= 4'b0000;
                data_arr_idx <= 4'b0000;
                // some counter
                pop_time <= 4'b0000;
                data_num <= 4'b0000;
            end

            default : begin end // do nothing
        endcase
    end
end
endmodule