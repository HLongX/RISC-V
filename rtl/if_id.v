module if_id (
    input clk,
    input rst,
    input stall,
    input flush,

    input [31:0] instr_in,
    input [31:0] pc_in,
    input [31:0] pc4_in,

    output reg [31:0] instr_out,
    output reg [31:0] pc_out,
    output reg [31:0] pc4_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        instr_out <= 32'h00000013;
        pc_out    <= 0;
        pc4_out   <= 0;
    end else if (flush) begin
        instr_out <= 32'h00000013; // NOP: ADDI x0, x0, 0
        pc_out    <= 0;
        pc4_out   <= 0;
    end else if (!stall) begin
        instr_out <= instr_in;
        pc_out    <= pc_in;
        pc4_out   <= pc4_in;
    end
end

endmodule
