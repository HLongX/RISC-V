`timescale 1ns/1ps

module ALU_tb;

reg [31:0] A, B;
reg [3:0] ALU_Sel;
wire [31:0] ALU_Out;
wire Zero;

// Instantiate ALU
ALU uut (
    .A(A),
    .B(B),
    .ALU_Sel(ALU_Sel),
    .ALU_Out(ALU_Out),
    .Zero(Zero)
);

initial begin
    $display("Starting ALU Test...");
    
    // ADD
    A = 10; B = 5; ALU_Sel = 4'b0000;
    #10;
    $display("ADD: %d", ALU_Out);

    // SUB
    A = 10; B = 5; ALU_Sel = 4'b0001;
    #10;
    $display("SUB: %d", ALU_Out);

    // AND
    A = 10; B = 6; ALU_Sel = 4'b0010;
    #10;
    $display("AND: %d", ALU_Out);

    // OR
    A = 10; B = 6; ALU_Sel = 4'b0011;
    #10;
    $display("OR: %d", ALU_Out);

    // XOR
    A = 10; B = 6; ALU_Sel = 4'b0100;
    #10;
    $display("XOR: %d", ALU_Out);

    // SLT
    A = 3; B = 5; ALU_Sel = 4'b0101;
    #10;
    $display("SLT: %d", ALU_Out);

    // SLL
    A = 2; B = 1; ALU_Sel = 4'b0110;
    #10;
    $display("SLL: %d", ALU_Out);

    // SRL
    A = 8; B = 1; ALU_Sel = 4'b0111;
    #10;
    $display("SRL: %d", ALU_Out);

    // ZERO FLAG TEST
    A = 5; B = 5; ALU_Sel = 4'b0001;
    #10;
    $display("Zero flag: %b", Zero);

    $stop;
end

endmodule