module Top;

wire q ,qbar;
reg set, reset;

// SR_Latch module
SR_Latch sr_m(.Q(q), .Qbar(qbar), .Sbar(set), .Rbar(reset));

initial begin
    $monitor($time, " set = %b, reset = %b, q = %b, qbar = %b\n", set, reset, q, qbar);
    set = 0; reset = 0;
    #5 reset = 1;
    #5 reset = 0;
    #5 set = 1;
    #5 $finish;
end

endmodule