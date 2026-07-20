module alu(A, B, ALUcontrol, result, zero);
  input [31:0] A, B;
  input [3:0] ALUcontrol;
  output reg [31:0] result;
  output zero;
  
  assign zero = (result == 32'b0);
  always @(*) begin
    case(ALUcontrol)
      4'b0000 : result = A + B;
      4'b0001 : result = A - B;
      4'b0010 : result = A & B;
      4'b0011 : result = A | B;
      4'b0100 : result = A ^ B;
      4'b0101 : result = A << B[4:0];
      4'b0110 : result = A >> B[4:0];
      4'b0111 : result = $signed(A) >>> B[4:0];
      4'b1000 : result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
      4'b1001 : result = (A < B) ? 32'b1 : 32'b0;
      default : result = 32'b0;
    endcase
  end
endmodule
