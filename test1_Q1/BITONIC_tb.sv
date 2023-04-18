`timescale 10ns / 1ps
`define CYCLE 10

`define BIPAT   "./test_data.dat"
`define GOLDEN1   "./s1_golden_data.dat"
`define GOLDEN2   "./s2_golden_data.dat"
`define GOLDEN3   "./s3_golden_data.dat"

`define SWPAT   "./sw_test_data.dat"
`define ASGOLDEN   "./as_golden_data.dat"
`define DSGOLDEN   "./ds_golden_data.dat"

module BITONIC_tb ();




parameter  TEST_N_PAT = 4096;
parameter  SW_N_PAT = 128;

integer bd;
integer bg1;
integer bg2;
integer bg3;

integer sd;
integer as;
integer ds;

integer i;
integer charcount;
integer  stage_1_fail;
integer  stage_2_fail;
integer  stage_3_fail;
integer  s1_fail_mess;
integer  s2_fail_mess;
integer  s3_fail_mess;

integer as_fail;
integer ds_fail;

string line;

reg  [63:0] number_in  ;
reg  [63:0] s1_num_out ;
reg  [63:0] s2_num_out ;
reg  [63:0] s3_num_out ;

reg  [63:0] s1_err_out [0:4];
reg  [63:0] s2_err_out [0:4];
reg  [63:0] s3_err_out [0:4];

reg  [63:0] s1_exp_out [0:4];
reg  [63:0] s2_exp_out [0:4];
reg  [63:0] s3_exp_out [0:4];

reg  [63:0] s1_err_pat [0:4];
reg  [63:0] s2_err_pat [0:4];
reg  [63:0] s3_err_pat [0:4];
reg  [63:0] number_gold;

reg  [15:0] sw_num_in  ;

reg  [15:0] as_num_out ;
reg  [15:0] ds_num_out ;

reg  [15:0] as_gold    ;
reg  [15:0] ds_gold    ;





BITONIC_AS u_BITONIC_as(    .number_in1(sw_num_in[15:8]), .number_in2(sw_num_in[7:0]), .number_out1(as_num_out[15:8]), .number_out2(as_num_out[7:0]));
BITONIC_DS u_BITONIC_ds(    .number_in1(sw_num_in[15:8]), .number_in2(sw_num_in[7:0]), .number_out1(ds_num_out[15:8]), .number_out2(ds_num_out[7:0]));

BITONIC_S1 u_BITONIC_s1(    .number_in1(number_in[63:56]), .number_in2(number_in[55:48]), .number_in3(number_in[47:40]), .number_in4(number_in[39:32]),
                            .number_in5(number_in[31:24]), .number_in6(number_in[23:16]), .number_in7(number_in[15:8]), .number_in8(number_in[7:0]),
                            .number_out1(s1_num_out[63:56]), .number_out2(s1_num_out[55:48]), .number_out3(s1_num_out[47:40]), .number_out4(s1_num_out[39:32]),
                            .number_out5(s1_num_out[31:24]), .number_out6(s1_num_out[23:16]), .number_out7(s1_num_out[15:8]), .number_out8(s1_num_out[7:0]));

BITONIC_S2 u_BITONIC_s2(    .number_in1(s1_num_out[63:56]), .number_in2(s1_num_out[55:48]), .number_in3(s1_num_out[47:40]), .number_in4(s1_num_out[39:32]),
                            .number_in5(s1_num_out[31:24]), .number_in6(s1_num_out[23:16]), .number_in7(s1_num_out[15:8]), .number_in8(s1_num_out[7:0]),
                            .number_out1(s2_num_out[63:56]), .number_out2(s2_num_out[55:48]), .number_out3(s2_num_out[47:40]), .number_out4(s2_num_out[39:32]),
                            .number_out5(s2_num_out[31:24]), .number_out6(s2_num_out[23:16]), .number_out7(s2_num_out[15:8]), .number_out8(s2_num_out[7:0]));

BITONIC_S3 u_BITONIC_s3(    .number_in1(s2_num_out[63:56]), .number_in2(s2_num_out[55:48]), .number_in3(s2_num_out[47:40]), .number_in4(s2_num_out[39:32]),
                            .number_in5(s2_num_out[31:24]), .number_in6(s2_num_out[23:16]), .number_in7(s2_num_out[15:8]), .number_in8(s2_num_out[7:0]),
                            .number_out1(s3_num_out[63:56]), .number_out2(s3_num_out[55:48]), .number_out3(s3_num_out[47:40]), .number_out4(s3_num_out[39:32]),
                            .number_out5(s3_num_out[31:24]), .number_out6(s3_num_out[23:16]), .number_out7(s3_num_out[15:8]), .number_out8(s3_num_out[7:0]));


initial begin
    sd = $fopen(`SWPAT,"r");
    if (sd == 0) begin
        $display ("swapper pattern handle null");
        $finish;
    end
end

initial begin
    as = $fopen(`ASGOLDEN,"r");
    if (as == 0) begin
        $display ("as golden handle null");
        $finish;
    end
end

initial begin
    ds = $fopen(`DSGOLDEN,"r");
    if (ds == 0) begin
        $display ("ds golden handle null");
        $finish;
    end
end


    
initial begin
    bd = $fopen(`BIPAT,"r");
    if (bd == 0) begin
        $display ("bitonic sorter pattern handle null");
        $finish;
    end
end

initial begin
    bg1 = $fopen(`GOLDEN1,"r");
    if (bg1 == 0) begin
        $display ("bitonic sorter s1 golden handle null");
        $finish;
    end
end

initial begin
    bg2 = $fopen(`GOLDEN2,"r");
    if (bg2 == 0) begin
        $display ("bitonic sorter s2 golden handle null");
        $finish;
    end
end

initial begin
    bg3 = $fopen(`GOLDEN3,"r");
    if (bg3 == 0) begin
        $display ("bitonic sorter s3 golden handle null");
        $finish;
    end
end
initial begin
    stage_1_fail = 0;
    stage_2_fail = 0;
    stage_3_fail = 0;

    s1_fail_mess = 0;
    s2_fail_mess = 0;
    s3_fail_mess = 0;

    as_fail = 0;
    ds_fail = 0;
end


initial begin
    $display("--------------- Simulation Start ----------------");
    for(i=0;i < SW_N_PAT ;i = i + 1)begin
        if (!$feof(sd)) begin
            charcount = $fgets (line, sd);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d", sw_num_in[15:8], sw_num_in[7:0]);
			end
            charcount = $fgets (line, as);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d", as_gold[15:8], as_gold[7:0]);
			end
            charcount = $fgets (line, ds);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d", ds_gold[15:8], ds_gold[7:0]);
			end
            if(as_num_out == as_gold)begin
            end else begin
                as_fail = 1;
            end
            if(ds_num_out == ds_gold)begin
            end else begin
                ds_fail = 1;
            end
        end
    end
    if(as_fail == 0) 
        $display("--           Acending Swapper PASS!            --");
    else
        $display("--  There are some errors in Acending Swapper  --");
    if(ds_fail == 0) 
        $display("--           Descending Swapper PASS!          --");
    else
        $display("-- There are some errors in Descending Swapper --");

    $fclose(sd);
    $fclose(as);
    $fclose(ds);

    for(i=0;i < TEST_N_PAT ;i = i + 1)begin
        if (!$feof(bd)) begin
		    charcount = $fgets (line, bd);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d %d %d %d %d %d %d", number_in[63:56], number_in[55:48], number_in[47:40],
                                     number_in[39:32], number_in[31:24], number_in[23:16], number_in[15:8], number_in[7:0]);
			end
			charcount = $fgets (line, bg1);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d %d %d %d %d %d %d", number_gold[63:56], number_gold[55:48], number_gold[47:40],
                                     number_gold[39:32], number_gold[31:24], number_gold[23:16], number_gold[15:8], number_gold[7:0]);
			end
            if(s1_num_out == number_gold)begin
            end
            else begin
                if(s1_fail_mess < 5)begin
                    #`CYCLE
                    s1_err_out[s1_fail_mess] = s1_num_out;
                    s1_exp_out[s1_fail_mess] = number_gold;
                    s1_err_pat[s1_fail_mess] = i;
                    s1_fail_mess = s1_fail_mess + 1;
                end
                stage_1_fail = stage_1_fail + 1;
            end

            charcount = $fgets (line, bg2);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d %d %d %d %d %d %d", number_gold[63:56], number_gold[55:48], number_gold[47:40],
                                     number_gold[39:32], number_gold[31:24], number_gold[23:16], number_gold[15:8], number_gold[7:0]);
			end
            if(s2_num_out == number_gold)begin
            end
            else begin
                if(s2_fail_mess < 5)begin
                    #`CYCLE
                    s2_err_out[s2_fail_mess] = s2_num_out;
                    s2_exp_out[s2_fail_mess] = number_gold;
                    s2_err_pat[s2_fail_mess] = i;
                    s2_fail_mess = s2_fail_mess + 1;
                end
                stage_2_fail = stage_2_fail + 1;
            end

            charcount = $fgets (line, bg3);
			if (charcount != 0) begin
                #`CYCLE
				charcount = $sscanf(line, "%d %d %d %d %d %d %d %d", number_gold[63:56], number_gold[55:48], number_gold[47:40],
                                     number_gold[39:32], number_gold[31:24], number_gold[23:16], number_gold[15:8], number_gold[7:0]);
			end
            if(s3_num_out == number_gold)begin
            end
            else begin
                if(s3_fail_mess < 5)begin
                    #`CYCLE
                    s3_err_out[s3_fail_mess] = s3_num_out;
                    s3_exp_out[s3_fail_mess] = number_gold;
                    s3_err_pat[s3_fail_mess] = i;
                    s3_fail_mess = s3_fail_mess + 1;
                end
                stage_3_fail = stage_3_fail + 1;
            end

        end
    end
        $display("-------------------------------------------------");
        $display("--           Stage 1 Simulation finish         --");
    if(stage_1_fail == 0) 
        $display("--                  Stage 1 PASS!              --");
    else begin
        for(i=0;i < s1_fail_mess;i = i + 1)begin
            $display("%d data is error !!", s1_err_pat[i]);
            $display("your data is      %d %d %d %d %d %d %d %d", s1_err_out[i][63:56], s1_err_out[i][55:48], s1_err_out[i][47:40], s1_err_out[i][39:32],
                    s1_err_out[i][31:24], s1_err_out[i][23:16], s1_err_out[i][15:8], s1_err_out[i][7:0]);
            $display("correct data is %d %d %d %d %d %d %d %d", s1_exp_out[i][63:56], s1_exp_out[i][55:48], s1_exp_out[i][47:40], s1_exp_out[i][39:32],
                    s1_exp_out[i][31:24], s1_exp_out[i][23:16], s1_exp_out[i][15:8], s1_exp_out[i][7:0]);
        end
        $display("--      There are %2d errors in stage 1       --", stage_1_fail);
    end

    
    $display("-------------------------------------------------");
    $display("--           Stage 2 Simulation finish         --");
    if(stage_2_fail == 0) 
    $display("--                  Stage 2 PASS!              --");
    else  begin
        for(i=0;i < s2_fail_mess;i = i + 1)begin
            $display("%d data is error !!", s2_err_pat[i]);
            $display("your data is    %d %d %d %d %d %d %d %d", s2_err_out[i][63:56], s2_err_out[i][55:48], s2_err_out[i][47:40], s2_err_out[i][39:32],
                    s2_err_out[i][31:24], s2_err_out[i][23:16], s2_err_out[i][15:8], s2_err_out[i][7:0]);
            $display("correct data is %d %d %d %d %d %d %d %d", s2_exp_out[i][63:56], s2_exp_out[i][55:48], s2_exp_out[i][47:40], s2_exp_out[i][39:32],
                    s2_exp_out[i][31:24], s2_exp_out[i][23:16], s2_exp_out[i][15:8], s2_exp_out[i][7:0]);
        end
        $display("--      There are %2d errors in stage 2       --", stage_2_fail);
    end
    $display("-------------------------------------------------");


    $display("--           Stage 3 Simulation finish         --");
    if(stage_3_fail == 0) 
    $display("--                  Stage 3 PASS!              --");
    else begin
        for(i=0;i < s3_fail_mess;i = i + 1)begin
            $display("%d data is error !!", s3_err_pat[i]);
            $display("your data is    %d %d %d %d %d %d %d %d", s3_err_out[i][63:56], s3_err_out[i][55:48], s3_err_out[i][47:40], s3_err_out[i][39:32],
                    s3_err_out[i][31:24], s3_err_out[i][23:16], s3_err_out[i][15:8], s3_err_out[i][7:0]);
            $display("correct data is %d %d %d %d %d %d %d %d", s3_exp_out[i][63:56], s3_exp_out[i][55:48], s3_exp_out[i][47:40], s3_exp_out[i][39:32],
                    s3_exp_out[i][31:24], s3_exp_out[i][23:16], s3_exp_out[i][15:8], s3_exp_out[i][7:0]);
        end
        $display("--      There are %2d errors in stage 3       --", stage_3_fail);
    end
    $display("--------------- Simulation End  -----------------");
    $fclose(bd);
    $fclose(bg1);
    $fclose(bg2);
    $fclose(bg3);

    #`CYCLE
    $finish;
end
endmodule