`timescale 1ns/1ps

module control_tb;

reg [31:0] instr;
reg BrEq, BrLT;

wire PCSel, RegWEn, BrUn, BSel, MemRW;
wire [1:0] ASel;
wire [2:0] ImmSel;
wire [3:0] ALUSel;
wire [1:0] WBSel;

ControlUnit uut (
    .instr(instr),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .PCSel(PCSel),
    .ImmSel(ImmSel),
    .RegWEn(RegWEn),
    .BrUn(BrUn),
    .BSel(BSel),
    .ASel(ASel),
    .ALUSel(ALUSel),
    .MemRW(MemRW),
    .WBSel(WBSel)
);

initial begin
    BrEq = 0; BrLT = 0;

    // ADD
    instr = 32'h002081B3;
    #10;

    // ADDI
    instr = 32'h00500093;
    #10;

    // LOAD
    instr = 32'h00002103;
    #10;

    // STORE
    instr = 32'h0020A023;
    #10;

    // BEQ (true)
    BrEq = 1;
    instr = 32'h00208663;
    #10;

    // BEQ (false)
    BrEq = 0;
    #10;

    $stop;
end

endmodule