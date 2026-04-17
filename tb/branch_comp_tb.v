`timescale 1ns/1ps

module branchcomp_tb;

reg [31:0] A, B;
reg BrUn;

wire BrEq, BrLT;

BranchComp uut (
    .A(A),
    .B(B),
    .BrUn(BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
);

initial begin
    // Equal
    A = 10; B = 10; BrUn = 0;
    #10;
    $display("EQ=%b LT=%b", BrEq, BrLT);

    // Signed less
    A = -5; B = 3; BrUn = 0;
    #10;

    // Unsigned compare
    A = -5; B = 3; BrUn = 1;
    #10;

    $stop;
end

endmodule