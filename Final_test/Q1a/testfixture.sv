`timescale 1ns/10ps
`define cycle 100              
`define terminate_cycle 5000   // Modify your terminate cycle here

module testfixture();

// Choose test pattern
//`define num_pattern "./dat/pattern1.data"
`define num_pattern "./dat/pattern.data"


// ------- Don't modify below ------- //

// Input
reg clk = 0;
reg rst = 0;
reg [7:0] ascii_in;
reg ready;

// Output
wire valid;
wire [6:0] result;

AEC u_AEC(.clk(clk), 
		  .rst(rst),
		  .ready(ready),
		  .ascii_in(ascii_in),
		  .valid(valid),
		  .result(result)
		  );



always begin #(`cycle/2) clk <= ~clk; end 


integer linedata;
initial begin
	linedata = $fopen(`num_pattern,"r");
	if(linedata == 0) begin
		$display("Please check your data path!");
	end
end


initial begin
	@(posedge clk); #1; rst = 1'b1;
	# (`cycle*2);
	@(posedge clk); #1; rst = 1'b0;
end


integer cycleCount = 0;
always@(posedge clk)begin
	cycleCount <= cycleCount + 1;
	if(cycleCount > `terminate_cycle) begin
		$display("-------------------------------------------------------------");
		$display("-----------------Fail waiting valid signal!------------------");
		$display("-----Please check your design or increase terminateCycle-----");
		$display("-------------------------------------------------------------");
		$fclose(linedata);
		$finish;
	end
end

string data;
string strNum;
string strData;
string strData_s;
string strData_s2;
string parenthesesCheck;

integer strIndex;
integer char_count;
integer err = 0;

reg readyEn;
reg [7:0] score;
reg [7:0] strAns;
reg [15:0] strNum_s;

initial begin
	$display("----------------------------------------------");
	$display("---------------Start Simulation---------------");
	char_count = $fgets(data, linedata);
	$display("       %s", data.substr(0,data.len()-2));
	char_count = $fgets(data, linedata);
end

// Send data
always@(negedge clk)begin
	if(rst) begin
		ready = 0;
		ascii_in = 0;
		readyEn = 1;
	end
	else begin
		if(readyEn==1)begin                       // Send first data
			ready = 1;                            
			readyEn = 0;
			ascii_in = strData.getc(strIndex);
			strIndex = strIndex + 1;
		end
		else if(valid==1)begin
			ready = 0;
			readyEn = 1; 
			strIndex = 0;  
		end
		else begin                                // Send data process
			ready = 0;
			if(strIndex<strData.len()-1)begin     // send test signal
				ascii_in = strData.getc(strIndex);
				strIndex = strIndex + 1;
			end
		end
	end
end


// ------- Check data and read new line ------- //
always@(negedge clk)begin
	if(rst) begin    // Read first pattern
		if(data.substr(0,3) == "num:")begin
			strIndex = 0;
			strNum = data.substr(4,5);
			parenthesesCheck = data.substr(7,7);
			strData_s = data.substr(9,10);
			strAns = strData_s.atoi();
			strData = data.substr(12,data.len()-1);
		end
	end
	else begin
		if (valid==1) begin      // From designer valid signal, check data and read new line
            strNum_s = strNum.atoi();
            strData_s2 = strData.substr(0,strData.len()-2);

            // Check data
            if(strAns==result)begin
            	//$display(" Pattern %2d : %s ", strNum_s, strData_s2);
            	//$display(" Expected answer:%d | get:%d --> Pass", strAns, result);
            end
            else begin
            	$display(" Pattern %2d : %s ", strNum_s, strData_s2);
            	$display(" Expected answer:%d | get:%d --> Fail", strAns, result);
            	err = err + 1;
            end

            // New case
            if(data.substr(0,3) == "Case")begin
				$display("\n%s", data.substr(0,data.len()-2));
				char_count = $fgets(data, linedata);
			end

            // Read new line 
            if(!$feof(linedata))begin            
				char_count = $fgets(data, linedata);

				if(data.substr(0,2) == "END")begin
					if(err==0)begin
						$display("----------------------------------------------------");
						$display("      Congratulations!!! You past all patterns!      ");
						$display("----------------------------------------------------");
					end
					else begin
						$display("\n");
						$display("----------------------------------------------------");
						$display("      There are %1d error in test patterns.", err    );
						$display("           Please check your design!!!"              );
						$display("----------------------------------------------------");
					end
					$finish;
				end
				
				if(data.substr(0,3) == "num:")begin
					strNum = data.substr(4,5);
					parenthesesCheck = data.substr(7,7);
					strData_s = data.substr(9,10);
					strAns = int'(strData_s.atoi());
					strData = data.substr(12,data.len()-1);
				end
			end
        end
	end
end


endmodule
