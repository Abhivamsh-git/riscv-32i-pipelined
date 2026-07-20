module imm_gen(instr, imm);
  input [31:0] instr;
  output reg [31:0] imm;
  
  wire [6:0] opcode = instr[6:0];
  
  always @(*) begin
    case(opcode)
      7'b0110011: imm = 32'b0; // R-type (No immediate)
      
      7'b0000011, 
      7'b0010011: imm = {{20{instr[31]}}, instr[31:20]}; // I-type
      
      7'b0100011: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // Store type (S-type)
      
      7'b1100011: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // Branch type (B-type)
      
      7'b1101111: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // Jump type (J-type)
      
      7'b0010111,
      7'b0110111: imm = {instr[31:12], 12'b0}; // U-type
      
      default:    imm = 32'b0;
    endcase
  end
endmodule 
