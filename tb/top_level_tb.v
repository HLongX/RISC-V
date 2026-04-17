`timescale 1ns/1ps

module cpu_tb;

reg clk, rst;

CPU uut (
    .clk(clk),
    .rst(rst)
);

// clock
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;

    // ================= PROGRAM =================
    uut.imem_inst.mem[0] = 32'h00500093; // addi x1, x0, 5
    uut.imem_inst.mem[1] = 32'h00300113; // addi x2, x0, 3

    uut.imem_inst.mem[2] = 32'h002081B3; // add  x3, x1, x2  = 8
    uut.imem_inst.mem[3] = 32'h40208233; // sub  x4, x1, x2  = 2
    uut.imem_inst.mem[4] = 32'h0020F2B3; // and  x5, x1, x2  = 1
    uut.imem_inst.mem[5] = 32'h0020E333; // or   x6, x1, x2  = 7
    uut.imem_inst.mem[6] = 32'h0020C3B3; // xor  x7, x1, x2  = 6

    uut.imem_inst.mem[7] = 32'h00209433; // sll  x8, x1, x2  = 5 << 3 = 40
    uut.imem_inst.mem[8] = 32'h0020D4B3; // srl  x9, x1, x2  = 5 >> 3 = 0

    uut.imem_inst.mem[9] = 32'h0020A533; // slt  x10, x1, x2 = 0 (5 < 3 false)

    // STORE / LOAD
    uut.imem_inst.mem[10] = 32'h00302023; // sw x3, 0(x0)
    uut.imem_inst.mem[11] = 32'h00002B03; // lw x22, 0(x0)

    // BRANCH (BEQ true → skip next)
    uut.imem_inst.mem[12] = 32'h016B0463; // beq x22, x3, +8
    uut.imem_inst.mem[13] = 32'h06300C93; // addi x25, x0, 99 (skip)
    uut.imem_inst.mem[14] = 32'h00100D13; // addi x26, x0, 1

    // NOP
    uut.imem_inst.mem[15] = 32'h00000013;

    // ================= RUN =================
    #10 rst = 0;

    #200;

    // ================= CHECK =================
    $display("x1  = %d", uut.rf.regfile[1]);   // 5
    $display("x2  = %d", uut.rf.regfile[2]);   // 3
    $display("x3  = %d", uut.rf.regfile[3]);   // 8
    $display("x4  = %d", uut.rf.regfile[4]);   // 2
    $display("x5  = %d", uut.rf.regfile[5]);   // 1
    $display("x6  = %d", uut.rf.regfile[6]);   // 7
    $display("x7  = %d", uut.rf.regfile[7]);   // 6
    $display("x8  = %d", uut.rf.regfile[8]);   // 40
    $display("x9  = %d", uut.rf.regfile[9]);   // 0
    $display("x10 = %d", uut.rf.regfile[10]);  // 0
    $display("x22 = %d", uut.rf.regfile[22]);  // 8
    $display("x25 = %d", uut.rf.regfile[25]);  // 0 (skip)
    $display("x26 = %d", uut.rf.regfile[26]);  // 1

    $stop;
end

endmodule