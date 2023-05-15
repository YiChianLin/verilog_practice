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
localparam MAXPOOLING = 3'd4;
localparam WRITE_LAYER1 = 3'd5;
localparam RESULT = 3'd6;

reg [2:0] i;    // for-loop index
reg [12:0] maxpooling_4_data [3:0];  // the block of maxpooling in 4 numbers
reg [12:0] sum_conv;				 // convolution summation

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
wire [12:0] cmp1, cmp2, max_data;

// reg flag;
initial begin
	filter_shift[0] <= 3'd0; // 1      1/1  2^(0)
	filter_shift[1] <= 3'd4; // 0.0625 1/16 2^(-4)
	filter_shift[2] <= 3'd3; // 0.125  1/8  2^(-3)
	filter_shift[3] <= 3'd4;
	filter_shift[4] <= 3'd2; // 0.25   1/4  2^(-2)
	filter_shift[5] <= 3'd2;
	filter_shift[6] <= 3'd4;
	filter_shift[7] <= 3'd3;
	filter_shift[8] <= 3'd4;
	bias <= 13'h1FF4;        // -0.75

	next_mem_offset[0] <=  12'd1;
	next_mem_offset[1] <=  12'd63;
	next_mem_offset[2] <=  12'd1;
	next_mem_offset[3] <=  12'hFC1; // -63
	counter_for_8 <= 4'd0;
	counter_for_4 <= 2'd0;
	current_pixel <= 12'd0;
	layer1_mem_idx <= 11'd0;
	sum_conv <= 13'd0;  	// convolution summation
	busy <= 0;  			// need to initialize
	csel <= 0;
end

// Atrous Convolution
always @(counter_for_8 or current_pixel) begin
	case (counter_for_8)
		0 : begin
			image_mem_idx <= current_pixel;
		end
		1 : begin
			if (current_pixel < 12'd128) begin
				image_mem_idx <= current_pixel - (current_pixel & 12'd64) - {current_pixel[5:0] > 1, current_pixel[5:0] == 1};
			end
			else begin
				image_mem_idx <= current_pixel - 12'd128 - {current_pixel[5:0] > 1, current_pixel[5:0] == 1};
			end
		end

		2 : begin
			if (current_pixel < 128) begin
				image_mem_idx <= current_pixel - (current_pixel[6] << 6);
			end
			else begin
				image_mem_idx <= current_pixel - 12'd128;
			end
		end

		3 : begin
			if (current_pixel < 12'd128) begin
				image_mem_idx <= current_pixel - (current_pixel & 12'd64) + {current_pixel[5:0] < 12'd62, current_pixel[5:0] == 12'd62};
			end
			else begin
				image_mem_idx <= current_pixel - 12'd128 + {current_pixel[5:0] < 12'd62, current_pixel[5:0] == 12'd62};
			end
		end

		4 : begin
			if (current_pixel[5:0] < 6'd2) begin
				image_mem_idx <= current_pixel & 12'b1111_1111_1110; // check the odd/even number				
			end
			else begin
				image_mem_idx <= current_pixel - 12'd2;
			end
		end
		
		5 : begin
			if (current_pixel[5:0] > 6'd61) begin
				image_mem_idx <= current_pixel + (current_pixel[0] ^ 1);
			end
			else begin
				image_mem_idx <= current_pixel + 12'd2;
			end
		end

		6 : begin
			if (current_pixel > 12'd3967) begin
				image_mem_idx <= current_pixel + ((current_pixel[6] ^ 1) << 6) - {current_pixel[5:0] > 1, current_pixel[5:0] == 1};
			end
			else begin
				image_mem_idx <= current_pixel + 12'd128 - {current_pixel[5:0] > 1, current_pixel[5:0] == 1};
			end
		end

		7 : begin
			if (current_pixel > 12'd3967) begin
				image_mem_idx <= current_pixel + ((current_pixel[6] ^ 1) << 6);
			end
			else begin
				image_mem_idx <= current_pixel + 12'd128;
			end
		end

		8 : begin
			if (current_pixel > 12'd3967) begin
				image_mem_idx <= current_pixel + ((current_pixel[6] ^ 1) << 6) + {current_pixel[5:0] < 12'd62, current_pixel[5:0] == 12'd62};
			end
			else begin
				image_mem_idx <= current_pixel + 12'd128 + {current_pixel[5:0] < 12'd62, current_pixel[5:0] == 12'd62};
			end
		end
		default: begin image_mem_idx <= current_pixel; end 
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
			// if run all index(0~8), convolution done
			if (counter_for_8 < 4'd9) begin
				Nextstate <= CONVOLUTION;
			end
			else begin
				Nextstate <= WRITE_RELU_LAYER0;
			end
		end

		WRITE_RELU_LAYER0 : begin
			// when write 
			if (counter_for_4 < 3'd3) begin
				Nextstate <= GET_DATA_FROM_MEM;
			end
			else begin
				Nextstate <= MAXPOOLING;
			end
		end

		MAXPOOLING : begin
			Nextstate <= WRITE_LAYER1;
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
		for (i = 0; i < 3'd4; i = i + 1) begin
			maxpooling_4_data[i] <= 13'd0;
		end	
	end
	else begin
		case (Currentstate) 
			CHECK_IMG_RD : begin
				// When ready pull up the busy signal
				if (ready) begin
					busy <= 1;
				end
			end 
			
			GET_DATA_FROM_MEM : begin
				// reset the write signal
				// cwr <= 0;

				// input the address of image memory to get data
				iaddr <= image_mem_idx;
				counter_for_8 <= 4'd1;
			end

			CONVOLUTION : begin
				// update the iaddr
				iaddr <= image_mem_idx;

				// Convolution for each pixel
				// If the shift kernel number(time 1) == 0
				if (filter_shift[counter_for_8 - 1]) begin
					sum_conv <= sum_conv + (~(idata >> filter_shift[counter_for_8-1]) + 1);
				end 
				else begin
					// if not shift, representing the middle of number
					sum_conv <= sum_conv + idata;
				end
				
				// next kernel index
				if (counter_for_8 == 9) begin
					counter_for_8 <= 4'd0;
				end
				else begin
					counter_for_8 <= counter_for_8 + 1;
				end
			end

			WRITE_RELU_LAYER0 : begin
				// write memory signal
				cwr <= 1;  // write enable
				csel <= 0; // write in Layer0
				caddr_wr <= current_pixel;// - next_mem_offset[counter_for_4]; // Layer0 addr

				current_pixel <= current_pixel + next_mem_offset[counter_for_4];

				// Add BIAS and RELU -> write in Layer0
				if ((sum_conv + bias) & 13'b1_0000_0000_0000) begin
					cdata_wr <= 0;
					maxpooling_4_data[counter_for_4] <= 0;
				end else begin
					cdata_wr <= sum_conv + bias;
					maxpooling_4_data[counter_for_4] <= sum_conv + bias;
				end
				// reset summation
				sum_conv <= 13'd0;

				// the counter of maxpooling block
				counter_for_4 <= counter_for_4 + 1;
			end

			MAXPOOLING : begin
				// reset the write signal
				cwr <= 0;
				current_pixel <= current_pixel + ((layer1_mem_idx[4:0] == 31) << 6);
			end

			WRITE_LAYER1 : begin
				cwr <= 1;  // write enable
				csel <= 1; // write in Layer1
				caddr_wr <= layer1_mem_idx; // Layer0 addr

				// Round up
				if (max_data & 13'b0_0000_0000_1111) begin
					cdata_wr <= (max_data & 13'b1_1111_1111_0000) + 13'b0_000_0001_0000;
				end
				else begin
					cdata_wr <= max_data;
				end
				layer1_mem_idx <= layer1_mem_idx + 1; 
			end

			RESULT : begin
				busy <= 0;
			end

			default: begin
				// do nothing
			end 
		endcase
	end
end

// combination circuit of maxpooling (ref by HW1 four numbers input maximum)
assign cmp1 = maxpooling_4_data[0] < maxpooling_4_data[1] ? maxpooling_4_data[1] : maxpooling_4_data[0];
assign cmp2 = maxpooling_4_data[2] < maxpooling_4_data[3] ? maxpooling_4_data[3] : maxpooling_4_data[2];
assign max_data = cmp1 < cmp2 ? cmp2 : cmp1;

endmodule