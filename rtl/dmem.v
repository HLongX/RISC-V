module DMEM (
    input clk,
    input [31:0] addr,
    input [31:0] DataW,
    input MemRW,        // 1: write, 0: read

    output [31:0] DataR
);

reg [31:0] mem [0:255];

// READ (combinational)
assign DataR = mem[addr[9:2]];

// WRITE (sequential)
always @(posedge clk) begin
    if (MemRW) begin
        mem[addr[9:2]] <= DataW;
    end
end

endmodule