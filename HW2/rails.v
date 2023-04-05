module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result; 
reg result, valid;

// Finite state machine
reg [1:0] Currentstate, Nextstate;
reg [3:0] input_data[10:0];    // pattern array
reg [3:0] stack[10:0];
reg [3:0] sp; 				  // stack point
reg [3:0] counter;			  // current time 
reg [3:0] idx;				  // pattern_data
reg [3:0] pop_time;		

reg done;
reg [3:0] i;
/* state 
ST0 : get all pattern number
ST1 : pattern number > counter -> push to stack
ST2 : pattern == top stack -> pop / sp = sp - 1
ST3 : check the pattern correctly
*/
parameter [1:0] ST0 = 2'b00,
				ST1 = 2'b01,
				ST2 = 2'b10,
				ST3 = 2'b11;

initial begin
	done = 0;
	sp = 0;
	counter = 0;
	idx = 0;
	pop_time = 0;
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
always @(data or Currentstate) begin
	case (Currentstate)
		ST0 : begin
			input_data[counter] = data;
			if (counter > input_data[0]) begin
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
			if (idx < (input_data[0] + 1)) begin
				for (i = 0; input_data[idx] > counter; i = i + 1)begin
					stack[sp] = counter + 1;
					counter = counter + 1;
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
			if (input_data[idx] == stack[sp]) begin
				pop_time = pop_time + 1;
				idx = idx + 1;
				Nextstate = ST1;
			end
			else begin
				Nextstate = ST3;
			end	
		end
		ST3 : begin
			done = ~done;
			if (pop_time ^ input_data[0]) begin
				Nextstate = ST0;
			end
			else begin
				Nextstate = ST0;
			end
		end
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

always @(done) begin
	sp <= 0;
	counter <= 0;
	idx <= 1;
	pop_time <= 0;
	for(i=0; i < 11; i = i +1)begin
      stack[i] <= 0;
	  input_data[i] <= 0;
    end
end
endmodule