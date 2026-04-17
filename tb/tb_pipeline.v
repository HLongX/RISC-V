`timescale 1ns/1ps

module pipeline_tb;

reg clk;

// Instantiate DUT
top_level_pipeline dut (
    .clk(clk)
);

// Clock 10ns
always #5 clk = ~clk;

// ================= INIT =================
initial begin
    clk = 0;
end

// ================= LOAD PROGRAM =================
initial begin
    // Bạn phải sửa IMEM để dùng mem[] bên trong

    // Example program (RISC-V assembly):
    /*
        addi x1, x0, 5
        addi x2, x0, 10
        add  x3, x1, x2
        add  x4, x3, x1   // RAW hazard (stall)
        lw   x5, 0(x3)
        add  x6, x5, x1   // load-use (stall)
        beq  x1, x1, skip
        addi x7, x0, 999  // should be flushed
    skip:
        addi x8, x0, 1
    */

    // Encode manually (RV32I)

    dut.imem_inst.mem[0] = 32'h00500093; // addi x1,x0,5
    dut.imem_inst.mem[1] = 32'h00a00113; // addi x2,x0,10
    dut.imem_inst.mem[2] = 32'h002081b3; // add x3,x1,x2
    dut.imem_inst.mem[3] = 32'h00118233; // add x4,x3,x1
    dut.imem_inst.mem[4] = 32'h0001a283; // lw x5,0(x3)
    dut.imem_inst.mem[5] = 32'h00128333; // add x6,x5,x1
    dut.imem_inst.mem[6] = 32'h00108063; // beq x1,x1,+8
    dut.imem_inst.mem[7] = 32'h3e700393; // addi x7,x0,999 (flush)
    dut.imem_inst.mem[8] = 32'h00100413; // addi x8,x0,1
end

// ================= MONITOR =================
initial begin
    $display("Time\tPC\t\t x1 x2 x3 x4 x5 x6 x7 x8");

    $monitor("%0t\t%h\t %d %d %d %d %d %d %d %d",
        $time,
        dut.pc,
        dut.rf.regs[1],
        dut.rf.regs[2],
        dut.rf.regs[3],
        dut.rf.regs[4],
        dut.rf.regs[5],
        dut.rf.regs[6],
        dut.rf.regs[7],
        dut.rf.regs[8]
    );
end

// ================= STOP =================
initial begin
    #300;
    $finish;
end

endmodule