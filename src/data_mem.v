module data_mem (
    input clk,
    input memwrite,
    input [2:0] funct3,
    input [31:0] address,
    input [31:0] write_data,
    output reg [31:0] read_data
);
  reg [31:0] mem[255:0];
  wire [31:0] raw_word;
  
  assign raw_word = mem[address[9:2]];
  
  // Read Data Processing (LB, LH, LW, LBU, LHU)
  always @(*) begin
    case (funct3)
      3'b000: begin // LB
        case (address[1:0])
          2'b00: read_data = {{24{raw_word[7]}},  raw_word[7:0]};
          2'b01: read_data = {{24{raw_word[15]}}, raw_word[15:8]};
          2'b10: read_data = {{24{raw_word[23]}}, raw_word[23:16]};
          2'b11: read_data = {{24{raw_word[31]}}, raw_word[31:24]};
        endcase
      end
      3'b001: begin // LH
        if (address[1]) read_data = {{16{raw_word[31]}}, raw_word[31:16]};
        else            read_data = {{16{raw_word[15]}}, raw_word[15:0]};
      end
      3'b010: read_data = raw_word; // LW
      3'b100: begin // LBU
        case (address[1:0])
          2'b00: read_data = {24'b0, raw_word[7:0]};
          2'b01: read_data = {24'b0, raw_word[15:8]};
          2'b10: read_data = {24'b0, raw_word[23:16]};
          2'b11: read_data = {24'b0, raw_word[31:24]};
        endcase
      end
      3'b101: begin // LHU
        if (address[1]) read_data = {16'b0, raw_word[31:16]};
        else            read_data = {16'b0, raw_word[15:0]};
      end
      default: read_data = raw_word;
    endcase
  end
  
  // Memory Writing Execution
  always @(posedge clk) begin
    if (memwrite) begin
      mem[address[9:2]] <= write_data;
    end
  end
endmodule 
