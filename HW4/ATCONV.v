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
localparam GET_DATA_FROM_MEM = 3'd1;
localparam CONVOLUTION = 3'd2;
localparam WRITE_RELU_LAYER0= 3'd3;
localparam WRITE_LAYER1 = 3'd4;
localparam RESULT = 3'd5;

// convolution summation
reg [12:0] sum_conv;				 

// memory idx
reg [11:0] image_mem_idx;   // max : 4095
reg [10:0] layer1_mem_idx;  // max : 1023
reg [11:0] current_pixel; 

// counter idx
reg [3:0] counter_for_8;  // for convolution 9 numbers element 
reg [1:0] counter_for_4;  // for maxpooling 4 numbers

// conv filter
reg [2:0] filter_shift[8:0];
reg [11:0] next_mem_offset[3:0];
reg [12:0] bias;

// maxpooling tmp reg
reg [12:0] max_data;

initial begin
	filter_shift[0] <= 3'd0; // 1      1/1  2^(0)
	filter_shift[1] <= 3'd4; // 0.0625 1/16 2^(-4)
	filter_shift[2] <= 3'd4;
	filter_shift[3] <= 3'd4;
	filter_shift[4] <= 3'd4;
	filter_shift[5] <= 3'd2;
	filter_shift[6] <= 3'd2; // 0.25   1/4  2^(-2)
	filter_shift[7] <= 3'd3; // 0.125  1/8  2^(-3)
	filter_shift[8] <= 3'd3;

	bias <= 13'h1FF4;        // -0.75

	next_mem_offset[0] <=  12'd1;
	next_mem_offset[1] <=  12'd63;
	next_mem_offset[2] <=  12'd1;
	next_mem_offset[3] <=  12'hFC1; // -63
	counter_for_8 <= 4'd0;
	counter_for_4 <= 2'd0;
	current_pixel <= 12'd0;
	layer1_mem_idx <= 11'd0;
	max_data <= 13'd0;
end

// Atrous Convolution
/*  kernel filter number
 *	
 * 	orignal:		improve:
 *  [1]	[2]	[3]		[1]	[7]	[2]
 *	[4]	[0]	[5]  => [6]	[0]	[5]
 *	[6]	[7]	[8]		[3]	[8]	[4]
 */
always @(counter_for_8 or current_pixel) begin
	case (counter_for_8)
		0 : begin
			image_mem_idx <= current_pixel;
		end
		
		1 : begin
			image_mem_idx <= {current_pixel[11:6] - {current_pixel[11:6] > 6'd1, current_pixel[11:6] == 6'd1}, current_pixel[5:0] - {current_pixel[5:0] > 6'd1, current_pixel[5:0] == 6'd1}};
		end

		2 : begin
			image_mem_idx <= {current_pixel[11:6] - {current_pixel[11:6] > 6'd1, current_pixel[11:6] == 6'd1}, current_pixel[5:0] + {current_pixel[5:0] < 6'd62, current_pixel[5:0] == 6'd62}};
		end

		3 : begin
			image_mem_idx <= {current_pixel[11:6] + {current_pixel[11:6] < 6'd62, current_pixel[11:6] == 6'd62}, current_pixel[5:0] - {current_pixel[5:0] > 6'd1, current_pixel[5:0] == 6'd1}};
		end

		4 : begin
			image_mem_idx <= {current_pixel[11:6] + {current_pixel[11:6] < 6'd62, current_pixel[11:6] == 6'd62}, current_pixel[5:0] + {current_pixel[5:0] < 6'd62, current_pixel[5:0] == 6'd62}};
		end

		5 : begin
			image_mem_idx <= {current_pixel[11:6], current_pixel[5:0] + {current_pixel[5:0] < 6'd62, current_pixel[5:0] == 6'd62}};
		end

		6 : begin
			image_mem_idx <= {current_pixel[11:6], current_pixel[5:0] - {current_pixel[5:0] > 6'd1, current_pixel[5:0] == 6'd1}};
		end

		7 : begin
			image_mem_idx <= {current_pixel[11:6] - {current_pixel[11:6] > 6'd1, current_pixel[11:6] == 6'd1}, current_pixel[5:0]};
		end

		8 : begin
			image_mem_idx <= {current_pixel[11:6] + {current_pixel[11:6] < 6'd62, current_pixel[11:6] == 6'd62}, current_pixel[5:0]};
		end

		default: begin image_mem_idx <= current_pixel; end // fixed latch problem
	endcase
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
			// Loading done
			if (ready) begin
				Nextstate <= GET_DATA_FROM_MEM;
			end
			else begin
				Nextstate <= CHECK_IMG_RD;
			end
		end 

		GET_DATA_FROM_MEM : begin
			// if calculate all pixel, end the process
			if (layer1_mem_idx < 11'd1024) begin
				Nextstate <= CONVOLUTION;
			end
			else begin
				Nextstate <= RESULT;
			end
		end

		CONVOLUTION : begin
			// if run all index(0~8) kernel filter, write into layer 0
			if (counter_for_8 < 4'd9) begin
				Nextstate <= CONVOLUTION;
			end
			else begin
				Nextstate <= WRITE_RELU_LAYER0;
			end
		end

		WRITE_RELU_LAYER0 : begin
			// when write into layer 0 four times, do maxpooling and write into layer1 
			if (counter_for_4 < 2'd3) begin
				Nextstate <= GET_DATA_FROM_MEM;
			end
			else begin
				Nextstate <= WRITE_LAYER1;
			end
		end

		WRITE_LAYER1 : begin
			Nextstate <= GET_DATA_FROM_MEM;
		end

		RESULT : begin
			Nextstate <= CHECK_IMG_RD;	
		end
		default: begin Nextstate <= CHECK_IMG_RD; end 
	endcase
end

// Conbination circuit
always @(posedge clk) begin
	if (reset) begin
		sum_conv <= 13'd0;  	// convolution summation
		busy <= 1'd0;  			// need to initialize
		csel <= 1'd0;
	end
	else begin
		case (Currentstate) 
			CHECK_IMG_RD : begin
				// When ready, pull up the busy signal
				busy <= ready;
			end 
			
			GET_DATA_FROM_MEM : begin
				// input the address of image memory to get data
				iaddr <= image_mem_idx;

				// the second kernel filter
				counter_for_8 <= 4'd1;
			end

			CONVOLUTION : begin
				// update the iaddr
				iaddr <= image_mem_idx;

				// Convolution for each pixel
				// If the shift kernel number(time 1) == 0
				if (filter_shift[counter_for_8 - 4'd1]) begin
					sum_conv <= sum_conv + (~(idata >> filter_shift[counter_for_8 - 4'd1]) + 13'd1);
				end 
				else begin
					// if not shift, representing the middle of number
					sum_conv <= sum_conv + idata;
				end
				
				if (counter_for_8 == 4'd9) begin
					// reset the counter
					counter_for_8 <= 4'd0;
				end
				else begin
					// next kernel filter
					counter_for_8 <= counter_for_8 + 4'd1;
				end
			end

			WRITE_RELU_LAYER0 : begin
				// write memory signal
				cwr <= 1'd1;  // write enable
				csel <= 1'd0; // write in Layer0
				caddr_wr <= current_pixel; // Layer0 addr

				// the next pixel of maxpooling block
				current_pixel <= current_pixel + next_mem_offset[counter_for_4];

				// RELU -> write in Layer0
				if (sum_conv & 13'b1_0000_0000_0000) begin
					cdata_wr <= 13'd0;
				end else begin
					cdata_wr <= sum_conv;
					// if the data > 0 and bigger than current max data, updata the neW value 
					if (max_data < sum_conv) begin
						max_data <= sum_conv;
					end 
				end

				// reset summation
				sum_conv <= bias;

				// the counter of maxpooling block
				counter_for_4 <= counter_for_4 + 2'd1;
			end

			WRITE_LAYER1 : begin
				// write memory signal
				csel <= 1'd1; // write in Layer1
				caddr_wr <= layer1_mem_idx; // Layer0 addr

				// Round up
				cdata_wr <= ((max_data >> 4) + (max_data[3:0] != 4'd0)) << 4;
				// reset the max data
				max_data <= 13'd0;

				// Layer 1 next memory
				layer1_mem_idx <= layer1_mem_idx + 11'd1; 

				// change the row of maxpooling block
				current_pixel <= current_pixel + ((layer1_mem_idx[4:0] == 5'd31) << 6);
			end

			RESULT : begin
				// check the answer
				busy <= 1'd0;
			end

			default: begin
				// do nothing
			end 
		endcase
	end
end

endmodule