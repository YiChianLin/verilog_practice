module AEC(clk, rst, ascii_in, ready, valid, result, parenthesesLegal);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;
output reg parenthesesLegal;

reg [2:0] nowState, nextState;
// 收一開始 input 資料
reg [6:0] dataBuffer [15:0];

reg [4:0] len;
// 陣列的引數
reg [4:0] arrPt, stackPt, outPt, number, right, left;

reg [6:0] OpStack   [15:0]; 
reg [6:0] OutBuffer [15:0]; 

reg [6:0] sum [15:0]; 
reg [3:0] sumPt ;

reg readEn;
parameter BUFFER    = 3'd0,
		  IN2POS    = 3'd1,
		  POP       = 3'd2,
		  CACULATE  = 3'd3,
		  RESULT    = 3'd4,
		  RESET     = 3'd5,
          CHECK     = 3'd6,
          ERROR     = 3'd7;



integer i;

always@(posedge clk or posedge rst) begin
	if (rst) begin
		nowState <= BUFFER;
		result <= 0;
		arrPt <= 0;
		stackPt <= 0;
		outPt <= 0;
		sumPt <= 0;
		valid <= 0; 
		len <= 0;
		readEn <= 0;
		for(i=0;i<16;i=i+1)begin
			OutBuffer[i]<=0;
			OpStack[i]<=0;
			dataBuffer[i]<=0;
			sum[i] <= 0;
		end
	end
	else begin
		nowState <= nextState;
		case(nowState)
			BUFFER:begin        
				if(ready) begin
					readEn <= 1;   
				end 
				if(ascii_in!=61 && (ready||readEn)) begin
					len <= len + 1;
					case(ascii_in)      // Mapping
						// number(0~9)
						48:  dataBuffer[len] <= 4'd0 ;  49: dataBuffer[len] <= 4'd1 ;  50: dataBuffer[len] <= 4'd2 ;
						51:  dataBuffer[len] <= 4'd3 ;  52: dataBuffer[len] <= 4'd4 ;  53: dataBuffer[len] <= 4'd5 ;
						54:  dataBuffer[len] <= 4'd6 ;  55: dataBuffer[len] <= 4'd7 ;  56: dataBuffer[len] <= 4'd8 ;
						57:  dataBuffer[len] <= 4'd9 ;  
						// number(10~15)
						97:  dataBuffer[len] <= 4'd10;  98: dataBuffer[len] <= 4'd11;
						99:  dataBuffer[len] <= 4'd12; 100: dataBuffer[len] <= 4'd13; 101: dataBuffer[len] <= 4'd14; 
						102: dataBuffer[len] <= 4'd15; 
						// operation
						default : begin 
                            dataBuffer[len] <=  ascii_in;
                            if (ascii_in == 40)
                                number <= number + 1; 

                            if (ascii_in == 41)
                                number <= number - 1;
                        end
                        
					endcase
				end
			end
            CHECK : begin
            
            end
			IN2POS:begin
				case(dataBuffer[arrPt])
					40:begin    // (     Put into stack
						OpStack[stackPt] <= dataBuffer[arrPt];
						stackPt <= stackPt + 1;
						arrPt <= arrPt + 1;
					end
					41:begin    // )     Put into stack
						if(OpStack[stackPt-1]!=40 && OpStack[stackPt-1]!=41)begin
							OutBuffer[outPt] <= OpStack[stackPt-1];
							outPt <= outPt + 1;
						end
						stackPt <= stackPt - 1;
						if(OpStack[stackPt-1]==40) arrPt <= arrPt + 1;
					end
					42:begin    // *
						if(OpStack[stackPt-1]==42 && stackPt!=0) begin 
							OutBuffer[outPt] <= OpStack[stackPt-1];
							stackPt <= stackPt -1 ;
							outPt <= outPt + 1;
						end
						else begin
							OpStack[stackPt] <= dataBuffer[arrPt];
							stackPt <= stackPt + 1;
							arrPt <= arrPt + 1;
						end
					end
					43, 45:begin  // + -
						if((OpStack[stackPt-1]==42 || OpStack[stackPt-1]==43 || OpStack[stackPt-1]==45) && stackPt!=0) begin 
							OutBuffer[outPt] <= OpStack[stackPt-1];
							stackPt <= stackPt -1 ;
							outPt <= outPt + 1;
						end
						else begin
							OpStack[stackPt] <= dataBuffer[arrPt];
							stackPt <= stackPt + 1;
							arrPt <= arrPt + 1;
						end
					end
					default:begin  // Normal number
						OutBuffer[outPt] <= dataBuffer[arrPt];
						outPt <= outPt + 1; 
						arrPt <= arrPt + 1;
					end
				endcase
			end
			POP:begin
                // 把 stack 清空
				if(stackPt!=0) begin
					stackPt <= stackPt - 1;
					if(OpStack[stackPt-1]!=40 && OpStack[stackPt-1]!=41)begin
						OutBuffer[outPt] <= OpStack[stackPt-1];
						outPt <= outPt + 1;
					end
				end
			end
			CACULATE:begin
				stackPt <= stackPt + 1;    
				case(OutBuffer[stackPt])
					42:begin
						sum[sumPt-2] <= sum[sumPt-2] * sum[sumPt-1];
						sumPt <= sumPt -1;
					end
					43:begin
						sum[sumPt-2] <= sum[sumPt-2] + sum[sumPt-1];
						sumPt <= sumPt -1;
					end
					45:begin
						sum[sumPt-2] <= sum[sumPt-2] - sum[sumPt-1];
						sumPt <= sumPt -1;
					end
					default:begin
						sum[sumPt] <= OutBuffer[stackPt];
						sumPt <= sumPt +1;
					end
				endcase
			end
			RESULT:begin
				valid <= 1; 
				result <= sum[sumPt-1];
                parenthesesLegal <= 1;
				arrPt <= 0;
				stackPt <= 0;
				outPt <= 0;
				sumPt <= 0;
				readEn <= 0;
				len <= 0;
				for(i=0;i<16;i=i+1)begin
					OutBuffer[i]<=0;
					OpStack[i]<=0;
					dataBuffer[i]<=0;
					sum[i] <= 0;
				end
			end
            ERROR:begin
                parenthesesLegal <= 0;
				valid <= 1; 
				result <= 123;
				arrPt <= 0;
				stackPt <= 0;
				outPt <= 0;
				sumPt <= 0;
				readEn <= 0;
				len <= 0;
				for(i=0;i<16;i=i+1)begin
					OutBuffer[i]<=0;
					OpStack[i]<=0;
					dataBuffer[i]<=0;
					sum[i] <= 0;
				end
			end
			RESET:begin
                number <= 0;
				valid <= 0;
			end
		endcase
	end
end



always@(*)begin
	case(nowState)
		BUFFER:begin
            // 收資料到 '='
			nextState = (ascii_in==61)? CHECK : BUFFER;
		end

        CHECK : begin
            if (number != 0) begin
                nextState = ERROR;
            end
            else begin
                nextState = IN2POS;
            end
        end
		IN2POS:begin
            // 把全部轉完
			nextState = (arrPt==len-1)? POP : IN2POS;
		end
		POP:begin
            // 把所有資料看完 再把 stack 都 pop 出來
			nextState = (stackPt==0)? CACULATE : POP;
		end
		CACULATE:begin
			nextState = (stackPt==outPt-1)? RESULT : CACULATE;
		end
		RESULT:begin
			nextState = RESET;
		end
		RESET:begin
			nextState = BUFFER;
		end
        ERROR : begin
            nextState = RESET;
        end
		default:begin
			nextState = BUFFER;
		end
	endcase
end

endmodule