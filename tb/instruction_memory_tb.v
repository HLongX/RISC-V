`timescale 1ns/1ps

module imem_tb;

reg [31:0] addr;
wire [31:0] instr;

IMEM uut (
    .addr(addr),
    .instr(instr)
);

initial begin
    // Initialize instruction memory with some test instructions
    uut.mem[0] = 32'h00500093; // addi x1,x0,5
    uut.mem[1] = 32'h00600113; // addi x2,x0,6
    uut.mem[2] = 32'h002081b3; // add x3,x1,x2

    addr = 0; #10;
    $display("instr = %h", instr);

    addr = 4; #10;
    $display("instr = %h", instr);

    addr = 8; #10;
    $display("instr = %h", instr);

    $stop;
end

endmodule