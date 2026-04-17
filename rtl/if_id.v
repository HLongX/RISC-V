module if_id (
    input clk,
    input stall,
    input flush,

    input [31:0] instr_in,
    input [31:0] pc_in,

    output reg [31:0] instr_out,
    output reg [31:0] pc_out
);

always @(posedge clk) begin
    if (flush) begin
        instr_out <= 32'b0; // NOP
        pc_out    <= 0;
    end
    else if (!stall) begin
        instr_out <= instr_in;
        pc_out    <= pc_in;
    end
end

endmodule