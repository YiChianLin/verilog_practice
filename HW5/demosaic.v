module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;

// state define
reg [2:0] Currentstate, Nextstate;
localparam CHECK_IMG_RD = 3'd0;
localparam CHECK_CENTER = 3'd1;
localparam RED_BLUE_MODE = 3'd2;
localparam GREEN_MODE= 3'd3;
localparam WRITE_IN_MEM = 3'd4;
localparam CHECK_NEXT_PIXEL = 3'd5;
localparam DONE = 3'd6;

reg [13:0] center_pixel;
reg [2:0] counter_for_2;
reg [3:0] counter_for_4;
reg [9:0] sum1, sum2;

// wire constants
wire [6:0] row_add1, row_minus1, col_add1, col_minus1;
assign row_add1 = center_pixel[13:7] + 7'd1;
assign row_minus1 = center_pixel[13:7] - 7'd1;
assign col_add1 = center_pixel[6:0] + 7'd1 ;
assign col_minus1 = center_pixel[6:0] - 7'd1;

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
            if ((in_en) && (center_pixel == 16383)) begin 
                Nextstate <= GREEN_MODE;
            end
            else begin
                Nextstate <= CHECK_IMG_RD;
            end
        end

        GREEN_MODE : begin
            if (counter_for_2 == 2) begin
                Nextstate <= WRITE_IN_MEM;
            end 
            else begin
                Nextstate <= GREEN_MODE;
            end
        end

        RED_BLUE_MODE : begin
            if (counter_for_4 == 4) begin
                Nextstate <= WRITE_IN_MEM;
            end 
            else begin
                Nextstate <= RED_BLUE_MODE;
            end
        end

        WRITE_IN_MEM : begin
            if (center_pixel == 16383) begin
                Nextstate <= DONE;
            end
            else begin
                Nextstate <= CHECK_NEXT_PIXEL;
            end
        end

        CHECK_NEXT_PIXEL : begin
            if (center_pixel[7] == center_pixel[0]) begin
                Nextstate <= GREEN_MODE;
            end
            else begin
                Nextstate <= RED_BLUE_MODE;
            end
        end

        DONE : begin
            Nextstate <= CHECK_IMG_RD;
        end

        default: begin
            Nextstate <= CHECK_IMG_RD;
        end
    endcase
end

// Conbination circuit
always @(posedge clk) begin
    if (reset) begin
		counter_for_2 <= 0;
		counter_for_4 <= 0;
        center_pixel <= 0;
        sum1 <= 0; // calculate summation
        sum2 <= 0; // calculate summation
        done <= 0;
	end
	else begin
        case (Currentstate)
            CHECK_IMG_RD : begin
                if (in_en) begin
                    case ({center_pixel[7], center_pixel[0]})
                        // Green mode
                        0, 3: begin
                            wr_g <= 1;
                            addr_g <= center_pixel;
                            wdata_g <= data_in;
                        end
                        // Red mode 
                        1: begin
                            wr_r <= 1'd1;
                            addr_r <= center_pixel;
                            wdata_r <= data_in;
                        end
                        // Blue mode
                        2: begin
                            wr_b <= 1'd1;
                            addr_b <= center_pixel;
                            wdata_b <= data_in;
                        end
                    endcase

                    // next input data
                    center_pixel <= center_pixel + 1;
                end
                else begin
                    // do nothing
                end
            end

            GREEN_MODE : begin
                // next pixel
                counter_for_2 <= counter_for_2 + 1;   

                // 依照 counter 儲存 tmp 值
                case (counter_for_2)
                    0 : begin
                        // center data (green)
                        wr_g <= 1'd0;
                        wr_r <= 1'd0;
                        wr_b <= 1'd0;
                        sum1 <= 0;
                        sum2 <= 0;

                        // 1 green odd
                        if ({center_pixel[7], center_pixel[0]}) begin
                            addr_r <= {row_minus1, center_pixel[6:0]};
                            addr_b <= {center_pixel[13:7], col_minus1};
                        end 
                        else begin
                            addr_r <= {center_pixel[13:7], col_minus1};
                            addr_b <= {row_minus1, center_pixel[6:0]};
                        end
                    end
                    1 : begin
                        sum1 <= rdata_r;
                        sum2 <= rdata_b;

                        if ({center_pixel[7], center_pixel[0]}) begin
                            addr_r <= {row_add1, center_pixel[6:0]};
                            addr_b <= {center_pixel[13:7], col_add1};
                        end 
                        else begin
                            addr_r <= {center_pixel[13:7], col_add1};
                            addr_b <= {row_add1, center_pixel[6:0]};
                        end
                    end
                    2 : begin
                        sum1 <= (sum1 + rdata_r) >> 1;
                        sum2 <= (sum2 + rdata_b) >> 1;
                    end

                    default: begin
                        // do nothing
                    end
                endcase
                             
            end

            RED_BLUE_MODE : begin
                // next pixel
                counter_for_4 <= counter_for_4 + 1;
                case (counter_for_4)
                    0 : begin
                        // center data (green)
                        wr_g <= 1'd0;
                        wr_r <= 1'd0;
                        wr_b <= 1'd0;
                        sum1 <= 0;
                        sum2 <= 0;

                        // next pixel
                        addr_g <= {row_minus1, center_pixel[6:0]};
                        if ({center_pixel[7], center_pixel[0]} == 2'd1) begin
                            // if center red
                            addr_b <= {row_minus1, col_minus1};
                        end 
                        else begin
                            // if center blue
                            addr_r <= {row_minus1, col_minus1};
                        end
                    end
                    1 : begin
                        sum1 <= rdata_g;
                        
                        // next pixel
                        addr_g <= {center_pixel[13:7], col_minus1};
                        if ({center_pixel[7], center_pixel[0]} == 2'd1) begin
                            // if center red
                            addr_b <= {row_minus1, col_add1};
                            sum2 <= rdata_b;
                        end 
                        else begin
                            // if center blue
                            addr_r <= {row_minus1, col_add1};
                            sum2 <= rdata_r;
                        end
                    end
                    2 : begin
                        sum1 <= sum1 + rdata_g;
                        
                        // next pixel
                        addr_g <= {center_pixel[13:7], col_add1};
                        if ({center_pixel[7], center_pixel[0]} == 2'd1) begin
                            // if center red
                            addr_b <= {row_add1, col_minus1};
                            sum2 <= sum2 + rdata_b;
                        end 
                        else begin
                            // if center blue
                            addr_r <= {row_add1, col_minus1};
                            sum2 <= sum2 + rdata_r;
                        end
                    end
                    3 : begin
                        sum1 <= sum1 + rdata_g; 
                        addr_g <= {row_add1, center_pixel[6:0]};
                        if ({center_pixel[7], center_pixel[0]} == 2'd1) begin
                            // if center red
                            addr_b <= {row_add1, col_add1};
                            sum2 <= sum2 + rdata_b;
                        end 
                        else begin
                            // if center blue
                            addr_r <= {row_add1, col_add1};
                            sum2 <= sum2 + rdata_r;
                        end
                    end
                    4 : begin
                        sum1 <= (sum1 + rdata_g) >> 2;
                        if ({center_pixel[7], center_pixel[0]} == 2'd1) begin
                            // if center red
                            sum2 <= (sum2 + rdata_b) >> 2;
                        end 
                        else begin
                            // if center blue
                            sum2 <= (sum2 + rdata_r) >> 2;
                        end
                    end

                    default: begin
                        // do nothing
                    end
                endcase
            end

            WRITE_IN_MEM : begin   
                case ({center_pixel[7], center_pixel[0]})
                    0, 3 : begin
                        wr_r <= 1'd1;
                        wr_b <= 1'd1;
                        addr_r <= center_pixel;
                        wdata_r <= sum1[7:0];
                        addr_b <= center_pixel;
                        wdata_b <= sum2[7:0];
                    end
                    1 : begin
                        wr_g <= 1'd1;
                        wr_b <= 1'd1;
                        addr_g <= center_pixel;
                        wdata_g <= sum1[7:0];
                        addr_b <= center_pixel;
                        wdata_b <= sum2[7:0];
                    end
                    2 : begin
                        wr_g <= 1'd1;
                        wr_r <= 1'd1;
                        addr_g <= center_pixel;
                        wdata_g <= sum1[7:0];
                        addr_r <= center_pixel;
                        wdata_r <= sum2[7:0];
                    end
                endcase
                counter_for_4 <= 0;
                counter_for_2 <= 0;
                sum1 <= 0;
                sum2 <= 0;
                center_pixel <= center_pixel + 1;
            end

            CHECK_NEXT_PIXEL : begin
                // do nothing
                wr_r <= 1'd0;
                wr_g <= 1'd0;
                wr_b <= 1'd0;
            end

            DONE : begin
                done <= 1;
            end

            default: begin
                // do nothing
            end
        endcase
    
    end
end
endmodule
