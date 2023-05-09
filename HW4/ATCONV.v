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
// localparam RELU_ADD_BIAS = 3'd3;
localparam WRITE_RELU_LAYER0= 3'd3;
localparam MAXPOOLING = 3'd4;
localparam WRITE_LAYER1 = 3'd5;
localparam RESULT = 3'd6;
localparam RESET = 3'd7;


// parameter BIT_DATA = 19;
reg [4:0] i;    // for-loop index
reg [12:0] maxpooling_4_data [3:0];  // the block of maxpooling in 4 numbers
reg [12:0] sum_conv;				 // convolution summation
reg [12:0] image_mem_idx;
reg [12:0] tmp_data;
reg [3:0] counter_for_9;
reg [3:0] counter_for_4;
// conv filter
reg [2:0] filter_shift[8:0];
reg [12:0] bias;

initial begin
	filter_shift[0] <= 3'd4; // 0.0625 1/16 2^(-4)
	filter_shift[1] <= 3'd3; // 0.125  1/8  2^(-3)
	filter_shift[2] <= 3'd4;
	filter_shift[3] <= 3'd2; // 0.25   1/4  2^(-2)
	filter_shift[4] <= 3'd0; // 1      1/1  2^(0)
	filter_shift[5] <= 3'd2;
	filter_shift[6] <= 3'd4;
	filter_shift[7] <= 3'd3;
	filter_shift[8] <= 3'd4;
	bias <= 13'h1FF4;        // -0.75
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
			if (image_mem_idx > 13'd4095) begin
				Nextstate <= RESULT;
			end
			else begin
				Nextstate <= CONVOLUTION;
			end
			
		end

		CONVOLUTION : begin
			// 9 number
			if (counter_for_9 < 4'd9) begin
				Nextstate <= GET_DATA_FROM_MEM;
			end
			else begin
				Nextstate <= WRITE_RELU_LAYER0;
			end
		end

		WRITE_RELU_LAYER0 : begin
			// when write 
			if (counter_for_4 < 2'd3) begin
				Nextstate <= GET_DATA_FROM_MEM;
			end
			else begin
				Nextstate <= MAXPOOLING;
			end
		end

		MAXPOOLING : begin
			Nextstate <= WRITE_RELU_LAYER1;
		end

		WRITE_RELU_LAYER1 : begin
			Nextstate <= GET_DATA_FROM_MEM;
		end

		RESULT : begin
			Nextstate <= RESET;	
		end

		RESET : begin
			Nextstate <= CHECK_IMG_RD;
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
		sum_conv <= 13'd0;  // convolution summation
		busy <= 0;  // need to initialize
		
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
				// input the address of image memory to get data
				iaddr <= image_mem_idx;
				image_mem_idx <= image_mem_idx + 1;
			end
			CONVOLUTION : begin
				// reset the write signal
				cwr <= 0;

				// Convolution for each pixel
				// If times the middle kernel number,  
				if (filter_shift[counter_for_9]) begin
					sum_conv = sum_conv + idata;
				end 
				else begin
					sum_conv = sum_conv + (~(idata >> filter_shift[counter_for_9]) + 1);
				end
				 

				// next memory
				image_mem_idx <= image_mem_idx + 1; 
				counter_for_9 <= counter_for_9 + 1;
				
				// tmp_data <= idata;
			end
			// RELU_ADD_BIAS : begin
				
			// end

			WRITE_RELU_LAYER0 : begin
				cwr <= 1;  // write enable
				csel <= 0; // write in Layer0
				caddr_wr <= image_mem_idx; // Layer0 addr
				// Add BIAS and RELU -> write in Layer0
				if ((sum_conv + bias) & 13'b1_0000_0000_0000) begin
					cdata_wr <= 0;
					maxpooling_4_data[counter_for_4] <= 0;
				end else begin
					cdata_wr <= sum_conv + bias;
					maxpooling_4_data[counter_for_4] <= sum_conv + bias;
				end
				
			end
			MAXPOOLING : begin
				// reset the write signal
				cwr <= 0;
				
				// compare four input numbers
				
			end
			WRITE_LAYER1 : begin
				csel <= 1; // write in Layer1
				// when 
				cwr <= 1;  // write enable
				caddr_wr <= image_mem_idx; // Layer0 addr

			end

			default: begin
			// do nothing
			end 
		endcase
	end

	
end


endmodule