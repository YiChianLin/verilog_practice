`timescale 1ns/10ps
module  ATCONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

// state define
reg [2:0] Currentstate, Nextstate;
localparam CHECK_IMG_RD = 3'd0;
localparam DATA_IN = 3'd1;
localparam CONVOLUTION = 3'd2;
localparam WRITE_LAYER0= 3'd3;
localparam MAXPOOLING = 3'd4;
localparam WRITE_LAYER1 = 3'd5;
localparam RESULT = 3'd6;
localparam RESET = 3'd7;


// parameter BIT_DATA = 19;
reg [4:0] i;    // for-loop index
reg [19:0] array_2x2 [3:0];
reg [19:0] sum_conv;
reg [11:0] image_mem_idx;
reg signed [12:0] tmp_data;
reg [3:0] counter_for_9;
reg [3:0] counter_for_4;
// conv filter
reg [12:0] filter_array[8:0];
reg [12:0] bias;

initial begin
	filter_array[0] <= 13'h1FFF;
	filter_array[1] <= 13'h1FFE;
	filter_array[2] <= 13'h1FFF;
	filter_array[3] <= 13'h1FFC;
	filter_array[4] <= 13'h0010;
	filter_array[5] <= 13'h1FFC;
	filter_array[6] <= 13'h1FFF;
	filter_array[7] <= 13'h1FFE;
	filter_array[8] <= 13'h1FFF;
	bias <= 13'h1FF4;
end

// sequential circuit
always @(posedge clk) begin
	if (reset) begin
		Currentstate <= CHECK_IMG_RD;
	end
	else begin
		Currentstate <= Nextstate;
	end 
end

// State control
always @(*) begin
	case (Currentstate)
		CHECK_IMG_RD : begin
			if (ready) begin
				Nextstate <= DATA_IN;
			end
			else begin
				Nextstate <= CHECK_IMG_RD;
			end
		end 

		DATA_IN : begin
			Nextstate <= CONVOLUTION;
		end

		CONVOLUTION : begin
			// 9 number
			if (counter_for_9 < 4'd9) begin
				Nextstate <= DATA_IN;
			end
			else begin
				Nextstate <= WRITE_LAYER0;
			end
		end

		WRITE_LAYER0 : begin
			// 4 times
			if (counter_for_4 < 4'd4) begin
				Nextstate <= WRITE_LAYER0;
			end
			else begin
				Nextstate <= MAXPOOLING;
			end
		end


		default: Nextstate <= CHECK_IMG_RD; 
	endcase
	
end

// Conbination circuit
always @(posedge clk) begin
	if (reset) begin
		for (i = 0; i < 3'd4; i = i + 1) begin
			array_2x2[i] <= 20'd0;
		end
		counter_for_9 <= 4'd0;
		counter_for_4 <= 4'd0;
		image_mem_idx <= 12'd0;
		sum_conv <= 20'd0;
		busy <= 0;  // need to initialize
		
	end
	else begin
		case (Currentstate) 
			CHECK_IMG_RD : begin
				if (ready) begin
					busy <= 1;
				end
			end 
			
			DATA_IN : begin
				// get data
				iaddr <= image_mem_idx;
				tmp_data <= idata;
				image_mem_idx <= image_mem_idx + 1;
			end
			CONVOLUTION : begin
				tmp_data <= idata;
				counter_for_9 <= counter_for_9 + 1;
			end

			WRITE_LAYER0 : begin
				csel <= 0;
			end

			default: begin
			// do nothing
			end 
		endcase
	end

	
end


endmodule