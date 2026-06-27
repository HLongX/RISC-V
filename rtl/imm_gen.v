module ImmGen (
    input [31:0] instr,
    input [2:0] ImmSel,
    output reg [31:0] imm
);

always @(*) begin
    case (ImmSel)

        // ========= I-TYPE =========
        3'b000: begin
            imm = {{20{instr[31]}}, instr[31:20]};
        end

        // ========= S-TYPE =========
        3'b001: begin
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        end

        // ========= B-TYPE =========
        3'b010: begin
            imm = {{19{instr[31]}},
                   instr[31],
                   instr[7],
                   instr[30:25],
                   instr[11:8],
                   1'b0};
        end

        // ========= J-TYPE =========
        3'b011: begin
            imm = {{11{instr[31]}},
                   instr[31],
                   instr[19:12],
                   instr[20],
                   instr[30:21],
                   1'b0};
        end

        // ========= U-TYPE (LUI / AUIPC) =========
        3'b100: begin
            imm = {instr[31:12], 12'b0};
        end

        default: begin
            imm = 32'd0;
        end
    endcase
end

endmodule