module control_unit(opcode, funct3, funct7_5, regwrite, memwrite, ALUsrcb_sel, MemtoReg, branch, jump, jalr, ALUcontrol);
  input [6:0] opcode;
  input [2:0] funct3;
  input funct7_5;
  output reg regwrite;
  output reg memwrite;
  output reg [1:0] ALUsrcb_sel;
  output reg MemtoReg;
  output reg branch;
  output reg jump;
  output reg jalr;
  output reg [3:0] ALUcontrol;
  
  reg [1:0] ALUop;
  
  reg src_a_pc;
  
  always @(*) begin
    regwrite    = 1'b0;
    ALUsrcb_sel = 2'b00;
    src_a_pc    = 1'b0;
    memwrite    = 1'b0;
    MemtoReg    = 1'b0;
    branch      = 1'b0;
    jump        = 1'b0;
    jalr        = 1'b0;
    ALUop       = 2'b00;
    
    case(opcode)
      7'b0110011: begin //Reg type
        regwrite = 1'b1;
        ALUop    = 2'b10;
      end
      
      7'b0010011: begin //Imm type
        regwrite    = 1'b1;
        ALUsrcb_sel = 2'b01;
        ALUop       = 2'b11;
      end
      
      7'b0000011: begin //Load type
        regwrite    = 1'b1;
        ALUsrcb_sel = 2'b01;
        MemtoReg    = 1'b1;
      end
      
      7'b0100011: begin //Store type
        ALUsrcb_sel = 2'b01;
        memwrite    = 1'b1;
      end
      
      7'b1100011: begin //Branch type
        branch   = 1'b1;
        ALUop    = 2'b01;
      end
      
      7'b1101111: begin //Jump type, JAL
        regwrite    = 1'b1;
        jump        = 1'b1;
        ALUsrcb_sel = 2'b00;
      end
      
      7'b1100111: begin // JALR
        regwrite    = 1'b1;
        jump        = 1'b1;
        jalr        = 1'b1;
        ALUsrcb_sel = 2'b10;
      end
      
      7'b0010111: begin // AUIPC
        regwrite    = 1'b1;
        src_a_pc    = 1'b1;
        ALUsrcb_sel = 2'b01;
      end
      
      7'b0110111: begin // LUI 
        regwrite = 1'b1;
      end
    endcase
  end
  
  always @(*) begin
    case(ALUop)
      2'b00: ALUcontrol = 4'b0000; // Add - for memory offset
      2'b01: ALUcontrol = 4'b0001; // Sub - for branch evaluation
      2'b10: begin // R-type
        case(funct3)
          3'b000: ALUcontrol = (funct7_5) ? 4'b0001 : 4'b0000;
          3'b001: ALUcontrol = 4'b0101;
          3'b010: ALUcontrol = 4'b1000;
          3'b011: ALUcontrol = 4'b1001;
          3'b100: ALUcontrol = 4'b0100;
          3'b101: ALUcontrol = (funct7_5) ? 4'b0111 : 4'b0110;
          3'b110: ALUcontrol = 4'b0011;
          3'b111: ALUcontrol = 4'b0010;
          default: ALUcontrol = 4'b0000;
        endcase
      end
      2'b11: begin // I-type
        case(funct3)
          3'b000: ALUcontrol = 4'b0000;
          3'b001: ALUcontrol = 4'b0101;
          3'b010: ALUcontrol = 4'b1000;
          3'b011: ALUcontrol = 4'b1001;
          3'b100: ALUcontrol = 4'b0100;
          3'b101: ALUcontrol = (funct7_5) ? 4'b0111 : 4'b0110;
          3'b110: ALUcontrol = 4'b0011;
          3'b111: ALUcontrol = 4'b0010;
          default: ALUcontrol = 4'b0000;
        endcase
      end
      default: ALUcontrol = 4'b0000;
    endcase
  end
endmodule
