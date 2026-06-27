// Pipeline control unit — no BrEq/BrLT inputs; branch decision deferred to EX stage.
// ASel encoding: 2'b00 = rs1, 2'b01 = PC, 2'b10 = zero (for LUI)
module control_unit (
    input [31:0] instr,
    output reg RegWrite,
    output reg MemRW,
    output reg [1:0] ResultSrc,
    output reg [3:0] ALUControl,
    output reg ALUSrc,
    output reg [1:0] ASel,
    output reg Branch,
    output reg Jump,
    output reg BrUn,
    output reg [2:0] ImmSel
);

wire [6:0] opcode = instr[6:0];
wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

always @(*) begin
    RegWrite   = 0;
    MemRW      = 0;
    ResultSrc  = 2'b00;
    ALUControl = 4'b0000;
    ALUSrc     = 0;
    ASel       = 2'b00;
    Branch     = 0;
    Jump       = 0;
    BrUn       = 0;
    ImmSel     = 3'b000;

    case (opcode)

        // R-type
        7'b0110011: begin
            RegWrite  = 1;
            ResultSrc = 2'b00;
            case ({funct7, funct3})
                {7'b0000000, 3'b000}: ALUControl = 4'b0000; // ADD
                {7'b0100000, 3'b000}: ALUControl = 4'b0001; // SUB
                {7'b0000000, 3'b111}: ALUControl = 4'b0010; // AND
                {7'b0000000, 3'b110}: ALUControl = 4'b0011; // OR
                {7'b0000000, 3'b100}: ALUControl = 4'b0100; // XOR
                {7'b0000000, 3'b010}: ALUControl = 4'b0101; // SLT
                {7'b0000000, 3'b011}: ALUControl = 4'b1001; // SLTU
                {7'b0000000, 3'b001}: ALUControl = 4'b0110; // SLL
                {7'b0000000, 3'b101}: ALUControl = 4'b0111; // SRL
                {7'b0100000, 3'b101}: ALUControl = 4'b1000; // SRA
                default:              ALUControl = 4'b0000;
            endcase
        end

        // I-type ALU (ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTIU)
        7'b0010011: begin
            RegWrite  = 1;
            ALUSrc    = 1;
            ResultSrc = 2'b00;
            ImmSel    = 3'b000;
            case (funct3)
                3'b000: ALUControl = 4'b0000; // ADDI
                3'b010: ALUControl = 4'b0101; // SLTI
                3'b011: ALUControl = 4'b1001; // SLTIU
                3'b100: ALUControl = 4'b0100; // XORI
                3'b110: ALUControl = 4'b0011; // ORI
                3'b111: ALUControl = 4'b0010; // ANDI
                3'b001: ALUControl = 4'b0110; // SLLI
                3'b101: ALUControl = funct7[5] ? 4'b1000 : 4'b0111; // SRAI / SRLI
                default: ALUControl = 4'b0000;
            endcase
        end

        // Load
        7'b0000011: begin
            RegWrite   = 1;
            ALUSrc     = 1;
            ResultSrc  = 2'b01;
            ALUControl = 4'b0000;
            ImmSel     = 3'b000;
        end

        // Store
        7'b0100011: begin
            MemRW      = 1;
            ALUSrc     = 1;
            ALUControl = 4'b0000;
            ImmSel     = 3'b001;
        end

        // Branch
        7'b1100011: begin
            ASel       = 2'b01; // PC as ALU input A → target = PC + imm
            ALUSrc     = 1;
            ALUControl = 4'b0000;
            Branch     = 1;
            ImmSel     = 3'b010;
            BrUn       = (funct3 == 3'b110) || (funct3 == 3'b111); // BLTU, BGEU
        end

        // JAL
        7'b1101111: begin
            RegWrite   = 1;
            ASel       = 2'b01; // PC + imm
            ALUSrc     = 1;
            ALUControl = 4'b0000;
            ResultSrc  = 2'b10; // write PC+4 to rd
            Jump       = 1;
            ImmSel     = 3'b011;
        end

        // JALR
        7'b1100111: begin
            RegWrite   = 1;
            ASel       = 2'b00; // rs1 + imm (clear LSB in top-level)
            ALUSrc     = 1;
            ALUControl = 4'b0000;
            ResultSrc  = 2'b10;
            Jump       = 1;
            ImmSel     = 3'b000;
        end

        // LUI
        7'b0110111: begin
            RegWrite   = 1;
            ASel       = 2'b10; // zero as ALU input A → result = 0 + U-imm
            ALUSrc     = 1;
            ALUControl = 4'b0000;
            ResultSrc  = 2'b00;
            ImmSel     = 3'b100;
        end

        // AUIPC
        7'b0010111: begin
            RegWrite   = 1;
            ASel       = 2'b01; // PC + U-imm
            ALUSrc     = 1;
            ALUControl = 4'b0000;
            ResultSrc  = 2'b00;
            ImmSel     = 3'b100;
        end

        default: begin end
    endcase
end

endmodule


// Single-cycle control unit (used by top_level.v).
// ASel encoding: 2'b00 = rs1, 2'b01 = PC, 2'b10 = zero (for LUI)
module ControlUnit (
    input [31:0] instr,
    input BrEq,
    input BrLT,

    output reg PCSel,
    output reg [2:0] ImmSel,
    output reg RegWEn,
    output reg BrUn,
    output reg BSel,
    output reg [1:0] ASel,
    output reg [3:0] ALUSel,
    output reg MemRW,
    output reg [1:0] WBSel
);

wire [6:0] opcode = instr[6:0];
wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

always @(*) begin
    PCSel   = 0;
    RegWEn  = 0;
    BrUn    = 0;
    BSel    = 0;
    ASel    = 2'b00;
    ALUSel  = 4'b0000;
    MemRW   = 0;
    WBSel   = 2'b00;
    ImmSel  = 3'b000;

    case (opcode)

        7'b0110011: begin
            RegWEn = 1;
            WBSel  = 2'b01;
            case ({funct7, funct3})
                {7'b0000000, 3'b000}: ALUSel = 4'b0000;
                {7'b0100000, 3'b000}: ALUSel = 4'b0001;
                {7'b0000000, 3'b111}: ALUSel = 4'b0010;
                {7'b0000000, 3'b110}: ALUSel = 4'b0011;
                {7'b0000000, 3'b100}: ALUSel = 4'b0100;
                {7'b0000000, 3'b010}: ALUSel = 4'b0101;
                {7'b0000000, 3'b011}: ALUSel = 4'b1001;
                {7'b0000000, 3'b001}: ALUSel = 4'b0110;
                {7'b0000000, 3'b101}: ALUSel = 4'b0111;
                {7'b0100000, 3'b101}: ALUSel = 4'b1000;
                default: ALUSel = 4'b0000;
            endcase
        end

        7'b0010011: begin
            RegWEn = 1;
            BSel   = 1;
            WBSel  = 2'b01;
            case (funct3)
                3'b000: ALUSel = 4'b0000;
                3'b010: ALUSel = 4'b0101;
                3'b011: ALUSel = 4'b1001;
                3'b100: ALUSel = 4'b0100;
                3'b110: ALUSel = 4'b0011;
                3'b111: ALUSel = 4'b0010;
                3'b001: ALUSel = 4'b0110;
                3'b101: ALUSel = funct7[5] ? 4'b1000 : 4'b0111;
                default: ALUSel = 4'b0000;
            endcase
        end

        7'b0000011: begin
            RegWEn = 1;
            BSel   = 1;
            WBSel  = 2'b00;
            ALUSel = 4'b0000;
        end

        7'b0100011: begin
            MemRW  = 1;
            BSel   = 1;
            ImmSel = 3'b001;
            ALUSel = 4'b0000;
        end

        7'b1100011: begin
            ASel   = 2'b01;
            BSel   = 1;
            ImmSel = 3'b010;
            case (funct3)
                3'b000: PCSel = BrEq;
                3'b001: PCSel = ~BrEq;
                3'b100: begin PCSel = BrLT;  BrUn = 0; end
                3'b101: begin PCSel = ~BrLT; BrUn = 0; end
                3'b110: begin PCSel = BrLT;  BrUn = 1; end
                3'b111: begin PCSel = ~BrLT; BrUn = 1; end
                default: PCSel = 0;
            endcase
        end

        7'b1101111: begin
            RegWEn = 1;
            PCSel  = 1;
            ASel   = 2'b01;
            BSel   = 1;
            ImmSel = 3'b011;
            WBSel  = 2'b10;
        end

        7'b1100111: begin
            RegWEn = 1;
            PCSel  = 1;
            ASel   = 2'b00; // rs1 + imm (LSB cleared in top_level)
            BSel   = 1;
            WBSel  = 2'b10;
        end

        // LUI
        7'b0110111: begin
            RegWEn = 1;
            ASel   = 2'b10; // zero → result = 0 + U-imm
            BSel   = 1;
            ImmSel = 3'b100;
            WBSel  = 2'b01;
        end

        // AUIPC
        7'b0010111: begin
            RegWEn = 1;
            ASel   = 2'b01; // PC + U-imm
            BSel   = 1;
            ImmSel = 3'b100;
            WBSel  = 2'b01;
        end

    endcase
end

endmodule
