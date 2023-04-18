module OR_AND_BEHAVIORAL(IN, OUT);
    input [3:0] IN;
    output OUT;
    reg OUT;
    always @(IN)
        begin
            OUT = (IN[0] | IN[1]) & (IN[2] | IN[3]);
        end
endmodule