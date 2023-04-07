// example of page.4-4
// ref SR_Latch turth table with nand gate : https://learn.digilentinc.com/Documents/255
module SR_Latch(Q, Qbar, Sbar, Rbar);

input Sbar, Rbar;
output Q, Qbar;

// double nand gate
// use verilog lib origin nand module
nand n1(Q, Sbar, Qbar);
nand n2(Qbar, Rbar, Q);

endmodule