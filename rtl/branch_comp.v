module BranchComp (
    input [31:0] A,
    input [31:0] B,
    input BrUn,

    output reg BrEq,
    output reg BrLT
);

always @(*) begin
    // Equal
    BrEq = (A == B);

    // Less than
    if (BrUn) begin
        // unsigned comparison
        BrLT = (A < B);
    end else begin
        // signed comparison
        BrLT = ($signed(A) < $signed(B));
    end
end

endmodule