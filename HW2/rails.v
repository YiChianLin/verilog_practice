module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result; 
reg result, valid;

/* Finite state machine : 
ST0 : get all pattern number
ST1 : pattern number > counter -> push to stack
ST2 : pattern == top stack -> pop / sp = sp - 1
ST3 : check the pattern correctly
*/
reg done, first_data_flag;
reg [1:0] Currentstate, Nextstate;
reg [3:0] input_data[10:0];    // pattern array, input_data[0] : the number of pattern
reg [3:0] stack[10:0];
reg [3:0] sp; 				   // stack point
reg [3:0] counter;			   // current time 
reg [3:0] pattern_arr_idx;	  
reg [3:0] pop_time;		
reg [3:0] i;				   // for-loop time to initial data

parameter [1:0] ST0 = 2'b00,
				ST1 = 2'b01,
				ST2 = 2'b10,
				ST3 = 2'b11;

// initial value
initial begin
	done = 0;
	sp = 0;
	counter = 0;
	pattern_arr_idx = 0;
	pop_time = 0;
	first_data_flag = 0;
end

// check the first input data
always @(posedge clk) begin
	if (input_data[1] > 0) begin
		first_data_flag = 0;
	end
	else if (input_data[0] > 0) begin
		first_data_flag = 1;
	end 
	else 
		first_data_flag = 0;
end

// Sequential circuut
always @(posedge clk or posedge reset) begin
	if (reset) begin
		Currentstate <= ST0;
	end
	else
		Currentstate <= Nextstate;
end

// Combination circuit for nextstate
always @(data or Currentstate or first_data_flag) begin
	case (Currentstate)
		ST0 : begin
			input_data[counter] = data;
			// check the first input data
			if (first_data_flag == 1) begin
				Nextstate = ST0;
			end
			else if (counter > input_data[0]) begin
				counter = 0;
				Nextstate = ST1;
			end
			else if(input_data[0] > 0) begin
				input_data[counter] = data;
				counter = counter + 1;
				Nextstate = ST0;
			end
			else 
				Nextstate = ST0;
		end
		ST1: begin
			if (pattern_arr_idx < (input_data[0] + 1)) begin
				for (; input_data[pattern_arr_idx] > counter; counter = counter + 1)begin
					stack[sp] = counter + 1;
					sp = sp + 1;
				end
				Nextstate = ST2;
			end
			else begin
				Nextstate = ST2;
			end
		end
		ST2 : begin
			sp = sp - 1;  // top stack thing
			if (input_data[pattern_arr_idx] == stack[sp]) begin
				pop_time = pop_time + 1;
				pattern_arr_idx = pattern_arr_idx + 1;
				Nextstate = ST1;
			end
			else begin
				Nextstate = ST3;
			end	
		end
		ST3 : begin	Nextstate = ST0; end
		default: begin Nextstate = ST0; end
	endcase
end

// Combination circuit for output
always @(Currentstate) begin
	case (Currentstate)
		ST0 : begin valid = 0; end
		ST1 : begin valid = 0; end
		ST2 : begin valid = 0; end
		ST3 : begin 
			done = ~done;
			valid = 1;
			if (pop_time ^ input_data[0]) begin
				result = 0;
			end
			else begin
				result = 1;
			end
		end
		default: begin valid = 0; end
	endcase
end

// reset
always @(done) begin
	first_data_flag <= 0;
	sp <= 0;
	counter <= 0;
	pattern_arr_idx <= 1;
	pop_time <= 0;
	for(i=0; i < 11; i = i + 1)begin
      stack[i] <= 0;
	  input_data[i] <= 0;
    end
end
endmodule