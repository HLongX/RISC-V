`timescale 1ns/1ps

module regfile_tb;

reg clk;
reg RegWrite;
reg [4:0] rs1, rs2, rd;
reg [31:0] wd;
wire [31:0] rd1, rd2;

RegFile uut (
    .clk(clk),
    .RegWrite(RegWrite),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .wd(wd),
    .rd1(rd1),
    .rd2(rd2)
);

// Clock
always #5 clk = ~clk;

initial begin
    clk = 0;

    // Write x1 = 10
    RegWrite = 1;
    rd = 5'd1;
    wd = 32'd10;
    #10;

    // Write x2 = 20
    rd = 5'd2;
    wd = 32'd20;
    #10;

    // Read x1, x2
    RegWrite = 0;
    rs1 = 5'd1;
    rs2 = 5'd2;
    #10;

    $display("x1 = %d, x2 = %d", rd1, rd2);

    // Test x0
    rs1 = 5'd0;
    #10;
    $display("x0 = %d (must be 0)", rd1);

    $stop;
end

endmodule