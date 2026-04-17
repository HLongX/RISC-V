module IMEM (
    input  [31:0] addr,
    output [31:0] instr
);

reg [31:0] mem [0:255];

// word aligned addressing
assign instr = mem[addr[9:2]];

endmodule