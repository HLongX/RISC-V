`timescale 1ns/1ps

module immgen_tb;

reg [31:0] instr;
reg [2:0] ImmSel;
wire [31:0] imm;

ImmGen uut (
    .instr(instr),
    .ImmSel(ImmSel),
    .imm(imm)
);

initial begin
    // I-type (addi x1,x0,5)
    instr = 32'h00500093;
    ImmSel = 3'b000;
    #10;
    $display("I-type imm = %h", imm);

    // S-type
    instr = 32'h0020A023;
    ImmSel = 3'b001;
    #10;
    $display("S-type imm = %h", imm);

    // B-type
    instr = 32'h00208663;
    ImmSel = 3'b010;
    #10;
    $display("B-type imm = %h", imm);

    // J-type
    instr = 32'h008000EF;
    ImmSel = 3'b011;
    #10;
    $display("J-type imm = %h", imm);

    $stop;
end

endmodule