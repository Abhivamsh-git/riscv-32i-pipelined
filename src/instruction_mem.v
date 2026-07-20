module instruction_mem (address, instr);
  input  wire [31:0] address;     
  output wire [31:0] instr;

  reg [31:0] imem [63:0]; 
  
  integer i;
  initial begin
    for (i = 0; i < 64; i = i + 1) begin 
      imem[i] = 32'b0;
    end
    
    // Executing Fibonacci program payload sequence
    imem[0]  = 32'h00000093; // addi x1, x0, 0
    imem[1]  = 32'h00100113; // addi x2, x0, 1
    imem[2]  = 32'h00000193; // addi x3, x0, 0
    imem[3]  = 32'h02800213; // addi x4, x0, 40
    imem[4]  = 32'h0011a023; // sw   x1, 0(x3)
    imem[5]  = 32'h00418193; // addi x3, x3, 4
    imem[6]  = 32'h0021a023; // sw   x2, 0(x3)
    imem[7]  = 32'h00418193; // addi x3, x3, 4
    imem[8]  = 32'h002082b3; // add  x5, x1, x2
    imem[9]  = 32'h0051a023; // sw   x5, 0(x3)
    imem[10] = 32'h00010093; // addi x1, x2, 0
    imem[11] = 32'h00028113; // addi x2, x5, 0
    imem[12] = 32'h00418193; // addi x3, x3, 4
    imem[13] = 32'hfe41c6e3; // blt  x3, x4, loop
    imem[14] = 32'h0000006f; // jal  x0, end
  end
  
  assign instr = imem[address[7:2]];
  
endmodule
