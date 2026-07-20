module reg_file(clk, wr, rs1, rs2, rd, wd, rd1, rd2);
  input clk, wr;
  input [4:0] rs1, rs2, rd;
  input [31:0] wd;
  output [31:0] rd1, rd2;
  
  reg [31:0] rf [31:0];
  
  assign rd1 = (rs1 == 5'b0) ? 32'b0 : 
               ((rs1 == rd) && wr) ? wd : rf[rs1];
               
  assign rd2 = (rs2 == 5'b0) ? 32'b0 : 
               ((rs2 == rd) && wr) ? wd : rf[rs2];
  
  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      rf[i] = 32'b0;
    end
  end
  
  always @(posedge clk) begin
    if(wr && (rd != 5'd0))
      rf[rd] <= wd;
  end
endmodule
