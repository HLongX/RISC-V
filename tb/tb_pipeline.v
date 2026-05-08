`timescale 1ns/1ps

module pipeline_tb;

reg clk, rst;

top_level_pipeline dut (
    .clk(clk),
    .rst(rst)
);

// 10 ns clock
always #5 clk = ~clk;

// ================= INIT =================
initial begin
    clk = 0;
    rst = 1;
end

// ================= LOAD PROGRAM =================
// Example program (RV32I, no forwarding — hazards handled by stalls):
//   addi x1, x0, 5
//   addi x2, x0, 10
//   add  x3, x1, x2       <- RAW on x1 (stall until x1 in WB)
//   add  x4, x3, x1       <- RAW on x3 (stall)
//   lw   x5, 0(x3)        <- RAW on x3 (stall)
//   add  x6, x5, x1       <- RAW on x5 (stall)
//   beq  x1, x1, +8       <- taken; flushes 2 instructions
//   addi x7, x0, 999      <- should be flushed
// skip:
//   addi x8, x0, 1

initial begin
    dut.imem_inst.mem[0] = 32'h00500093; // addi x1, x0, 5
    dut.imem_inst.mem[1] = 32'h00a00113; // addi x2, x0, 10
    dut.imem_inst.mem[2] = 32'h002081b3; // add  x3, x1, x2
    dut.imem_inst.mem[3] = 32'h00118233; // add  x4, x3, x1
    dut.imem_inst.mem[4] = 32'h0001a283; // lw   x5, 0(x3)
    dut.imem_inst.mem[5] = 32'h00128333; // add  x6, x5, x1
    dut.imem_inst.mem[6] = 32'h00108463; // beq  x1, x1, +8  (skip to mem[8])
    dut.imem_inst.mem[7] = 32'h3e700393; // addi x7, x0, 999 (must be flushed)
    dut.imem_inst.mem[8] = 32'h00100413; // addi x8, x0, 1

    // Release reset after 2 cycles
    #20 rst = 0;
end

// ================= MONITOR =================
initial begin
    $display("Time\tPC\t\t x1  x2  x3  x4  x5  x6  x7  x8");
    $monitor("%0t\t%h\t %d %d %d %d %d %d %d %d",
        $time,
        dut.pc,
        dut.rf.regfile[1],
        dut.rf.regfile[2],
        dut.rf.regfile[3],
        dut.rf.regfile[4],
        dut.rf.regfile[5],
        dut.rf.regfile[6],
        dut.rf.regfile[7],
        dut.rf.regfile[8]
    );
end

// ================= STOP =================
initial begin
    #500;
    $display("=== Final Register State ===");
    $display("x1=%0d (expect 5)",  dut.rf.regfile[1]);
    $display("x2=%0d (expect 10)", dut.rf.regfile[2]);
    $display("x3=%0d (expect 15)", dut.rf.regfile[3]);
    $display("x4=%0d (expect 20)", dut.rf.regfile[4]);
    $display("x6=%0d (expect 5+dmem[0])", dut.rf.regfile[6]);
    $display("x7=%0d (expect 0 — flushed)", dut.rf.regfile[7]);
    $display("x8=%0d (expect 1)",  dut.rf.regfile[8]);
    $stop;
end

endmodule
