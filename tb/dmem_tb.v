`timescale 1ns/1ps

module dmem_tb;

reg clk;
reg [31:0] addr;
reg [31:0] DataW;
reg MemRW;

wire [31:0] DataR;

DMEM uut (
    .clk(clk),
    .addr(addr),
    .DataW(DataW),
    .MemRW(MemRW),
    .DataR(DataR)
);

// clock
always #5 clk = ~clk;

initial begin
    clk = 0;

    // WRITE
    addr = 0;
    DataW = 32'h12345678;
    MemRW = 1;
    #10;

    // READ
    MemRW = 0;
    #10;
    $display("Read Data = %h", DataR);

    // WRITE another
    addr = 4;
    DataW = 32'hAABBCCDD;
    MemRW = 1;
    #10;

    // READ
    MemRW = 0;
    #10;
    $display("Read Data = %h", DataR);

    $stop;
end

endmodule