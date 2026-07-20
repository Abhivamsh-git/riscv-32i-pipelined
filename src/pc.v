module pc(clk, rstn, en, pc_next, pc_current);
  input clk, rstn, en;
  input [31:0] pc_next;
  output reg [31:0] pc_current;
  
  always @(posedge clk or negedge rstn) begin
    if(!rstn)
      pc_current <= 0;
    else if(en)
      pc_current <= pc_next;
  end
endmodule
