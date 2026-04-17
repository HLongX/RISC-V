module ControlUnit (
    input [31:0] instr,
    input BrEq,
    input BrLT,

    output reg PCSel,
    output reg [2:0] ImmSel,
    output reg RegWEn,
    output reg BrUn,
    output reg BSel,
    output reg ASel,
    output reg [3:0] ALUSel,
    output reg MemRW,
    output reg MemRead,     
    output reg [1:0] WBSel
);

wire [6:0] opcode = instr[6:0];
wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

always @(*) begin
    // default
    PCSel   = 0;
    RegWEn  = 0;
    BrUn    = 0;
    BSel    = 0;
    ASel    = 0;
    ALUSel  = 4'b0000;
    MemRW   = 0;
    MemRead = 0;   
    WBSel   = 2'b00;
    ImmSel  = 3'b000;

    case (opcode)

        // ================= R-TYPE =================
        7'b0110011: begin
            RegWEn = 1;
            ASel   = 0;
            BSel   = 0;
            WBSel  = 2'b01;

            case ({funct7, funct3})
                {7'b0000000, 3'b000}: ALUSel = 4'b0000; // ADD
                {7'b0100000, 3'b000}: ALUSel = 4'b0001; // SUB
                {7'b0000000, 3'b111}: ALUSel = 4'b0010; // AND
                {7'b0000000, 3'b110}: ALUSel = 4'b0011; // OR
                {7'b0000000, 3'b100}: ALUSel = 4'b0100; // XOR
                {7'b0000000, 3'b010}: ALUSel = 4'b0101; // SLT
                {7'b0000000, 3'b001}: ALUSel = 4'b0110; // SLL
                {7'b0000000, 3'b101}: ALUSel = 4'b0111; // SRL
                {7'b0100000, 3'b101}: ALUSel = 4'b1000; // SRA
                {7'b0000000, 3'b011}: ALUSel = 4'b1001; // SLTU (FIX funct3)
                default: ALUSel = 4'b0000;
            endcase
        end

        // ================= I-TYPE (ADDI) =================
        7'b0010011: begin
            RegWEn = 1;
            ASel   = 0;
            BSel   = 1;
            ImmSel = 3'b000;
            WBSel  = 2'b01;
            ALUSel = 4'b0000;
        end

        // ================= LOAD =================
        7'b0000011: begin
            RegWEn  = 1;
            ASel    = 0;
            BSel    = 1;
            ImmSel  = 3'b000;
            WBSel   = 2'b00;
            ALUSel  = 4'b0000;
            MemRead = 1;   
        end

        // ================= STORE =================
        7'b0100011: begin
            MemRW  = 1;
            ASel   = 0;
            BSel   = 1;
            ImmSel = 3'b001;
            ALUSel = 4'b0000;
        end

        // ================= BRANCH =================
        7'b1100011: begin
            ASel   = 1;
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

        // ================= JAL =================
        7'b1101111: begin
            RegWEn = 1;
            PCSel  = 1;
            ASel   = 1;
            BSel   = 1;
            ImmSel = 3'b011;
            WBSel  = 2'b10;
        end

        // ================= JALR =================
        7'b1100111: begin
            RegWEn = 1;
            PCSel  = 1;
            ASel   = 0;
            BSel   = 1;
            ImmSel = 3'b000;
            WBSel  = 2'b10;
        end

    endcase
end

endmodule