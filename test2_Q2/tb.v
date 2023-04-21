`timescale 1ns/10ps
`define CYCLE      50.0  
`define End_CYCLE  1000000000
`define RAILSNUM      "rails_num.dat"
`define PATTERN1    "test_data_rails1.dat"
`define PATTERN2    "test_data_rails2.dat"
`define EXPECT      "golden_data_rails.dat"

module testfixture();
parameter TEST_N_PAT = 300;

integer fd1;
integer fd2;
integer fn;
integer fg;
integer golden_result1;
integer golden_result2;
integer charcount;
integer pass=0;
integer p1_fail=0;
integer p2_fail=0;
integer p3_fail=0;
integer pattern_count=0;

reg [3:0] data1;
reg [3:0] data2;
reg [3:0] num;

reg clk = 0;
wire valid;
reg reset = 0;
wire result1;
wire result2;

rails u_rails(.clk(clk),
        .reset(reset),
        .number(num),
        .data1(data1),
        .data2(data2),
        .valid(valid),
        .result1(result1),
        .result2(result2));

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
    @(posedge clk);  #2 reset = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk);  #2  reset = 1'b0;
end

reg [31:0] cycle=0;

always @(posedge clk) begin
    cycle=cycle+1;
    if (cycle > `End_CYCLE) begin
        $display("--------------------------------------------------");
        $display("-- Failed waiting valid signal, Simulation STOP --");
        $display("--------------------------------------------------");
        $fclose(fn);
        $fclose(fd1);
        $fclose(fd2);
        $finish;
    end
end

initial begin
    fn = $fopen(`RAILSNUM,"r");
    if (fn == 0) begin
        $display ("rails number pattern handle null");
        $finish;
    end
end

initial begin
    fd1 = $fopen(`PATTERN1,"r");
    if (fd1 == 0) begin
        $display ("pattern handle null");
        $finish;
    end
end
initial begin
    fd2 = $fopen(`PATTERN2,"r");
    if (fd2 == 0) begin
        $display ("pattern2 handle null");
        $finish;
    end
end

initial begin
    fg = $fopen(`EXPECT,"r");
    if (fg == 0) begin
        $display ("golden handle null");
        $finish;
    end
end

// reg  valid_reg;
// always @(posedge clk) begin
//     valid_reg = valid;
// end
reg wait_valid;
reg get_result1;
reg get_result2;
reg first;
integer in_count;
integer ra_num;

always @(posedge clk) begin
    if (reset) begin
        wait_valid=0;
    end
    else begin
        if(wait_valid == 0) begin
            if(in_count == ra_num) wait_valid =1;
        end
        else begin
            if (valid ==1) begin
                wait_valid=0;
                get_result1 = result1;
                get_result2 = result2;

                charcount = $fscanf(fg, "%d %d", golden_result1,golden_result2);
                if(get_result1 == golden_result1 && get_result2 == golden_result2) begin
                    pass = pass +1;
                    $display("Pattern%0d: Station1 Expect= %1d Get= %d, Station2 Expect= %1d Get= %d, PASS\n",
                                        pattern_count,golden_result1,get_result1,golden_result2,get_result2);
                end
                else begin
                    if(golden_result1 == 0 && golden_result2 == 0)begin
                        p1_fail = p1_fail +1;
                    end else if(golden_result1 == 1 && golden_result2 == 1)begin
                        p2_fail = p2_fail +1;
                    end else if (golden_result1 == 1 && golden_result2 == 0)begin
                        p3_fail = p3_fail +1;
                    end
                    $display("Pattern%0d: Station1 Expect= %1d Get= %d, Station2 Expect= %1d Get= %d, FAIL\n",
                                        pattern_count,golden_result1,get_result1,golden_result2,get_result2);
                end
                pattern_count = pattern_count + 1;
            end
        end
    end
end

always @(negedge clk ) begin
    if (reset) begin
        in_count = 0;
        first = 1;
    end 
    else begin
        if (pattern_count < TEST_N_PAT) begin
            if(wait_valid ==0) begin
                if(first) begin
                    first = 0;
                    charcount = $fscanf(fn, "%d", num);
                    ra_num = num;
                    // number = num;
                end
                else begin
                    num = 4'dx;
                    charcount = $fscanf(fd1, "%d", data1);
                    charcount = $fscanf(fd2, "%d", data2);
                    in_count = in_count + 1;    
                end
            end
            else begin
                num = 4'dx;
                data1 = 4'dx;
                data2 = 4'dx;
                first = 1;
                in_count = 0;
            end
        end //if (!$feof(fd)) begin
        else begin
             $fclose(fd1);
             $fclose(fd2);
             $fclose(fn);
             $display ("-----------------------------------------------------------");
             $display ("----                 Simulation finish                 ----");
            if(p1_fail == 0)
              $display("----                 Patten 1 ALL PASS                 ----");
             else
              $display("----             Patten 1 FAIL , Fail = %2d             ----",p1_fail);
            if(p2_fail == 0)
              $display("----                 Patten 2 ALL PASS                 ----");
             else
              $display("----             Patten 2 FAIL , Fail = %2d             ----",p2_fail);
            if(p3_fail == 0)
              $display("----                 Patten 3 ALL PASS                 ----");
             else
              $display("----             Patten 3 FAIL , Fail = %2d             ----",p3_fail);
             $display ("-----------------------------------------------------------");
             $finish;
        end
    end
end
endmodule
