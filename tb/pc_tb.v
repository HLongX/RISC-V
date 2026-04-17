`timescale 1ns/1ps

module pc_tb;

reg clk, rst;
wire [31:0] pc;
wire [31:0] next_pc;

assign next_pc = pc + 4;

PC uut (
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc(pc)
);

// clock
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    #10;

    rst = 0;

    #50;
    $stop;
end

endmodule