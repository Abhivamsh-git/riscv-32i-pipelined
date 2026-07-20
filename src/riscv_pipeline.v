module riscv_pipeline(clk, rstn);
  input clk, rstn;
  
  wire [31:0] pc_current;
  wire [31:0] pc_next;
  wire [31:0] instr;
  wire [31:0] rd1, rd2;
  wire [31:0] imm;
  wire [31:0] alu_srcb;
  wire [31:0] alu_result;
  wire alu_zero;
  
  wire regwrite, memwrite, memtoreg, branch, jump, jalr;
  wire [1:0] ALU_srcb_sel;
  wire [3:0] ALUcontrol;
  
  wire [31:0] mem_read_data;
  wire [31:0] final_write_back_data;
  
  wire pcsrc;
  wire [31:0] pc_plus4;
  wire [31:0] pc_target;
   
  wire lw_stall;
  
  reg [31:0] alu_operand_a;
  reg [31:0] intermediate_operand_b;
  reg [1:0] ForwardA;
  reg [1:0] ForwardB;

  // Pipeline structural registers declaration
  reg [31:0] IF_ID_pc;
  reg [31:0] IF_ID_instr;
  
  reg [31:0] ID_EX_pc;
  reg [31:0] ID_EX_rd1;
  reg [31:0] ID_EX_rd2;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_instr;
  reg [4:0]  ID_EX_rd;
  reg [1:0]  ID_EX_ALU_srcb_sel;
  reg [3:0]  ID_EX_ALUcontrol;
  reg        ID_EX_memwrite;
  reg        ID_EX_memtoreg;
  reg        ID_EX_regwrite;
  reg        ID_EX_jump;
  reg        ID_EX_branch;
  reg [31:0] ID_EX_pc_plus4;

  reg [31:0] EX_MEM_instr;
  reg [31:0] EX_MEM_alu_result;
  reg [31:0] EX_MEM_write_data;
  reg [4:0]  EX_MEM_rd;
  reg        EX_MEM_memwrite;
  reg        EX_MEM_memtoreg;
  reg        EX_MEM_regwrite;
  reg        EX_MEM_jump;
  reg [31:0] EX_MEM_pc_plus4;

  reg [31:0] MEM_WB_instr;
  reg [31:0] MEM_WB_alu_result;
  reg [31:0] MEM_WB_read_data;
  reg [4:0]  MEM_WB_rd;
  reg        MEM_WB_memtoreg;
  reg        MEM_WB_regwrite;
  reg        MEM_WB_jump;
  reg [31:0] MEM_WB_pc_plus4;

  wire decode_pcsrc;
  wire [31:0] ID_pc_target;
  wire [31:0] EX_pc_target;

  wire [31:0] jalr_target;
  assign jalr_target = (rd1 + imm) & 32'hfffffffe;
  
  // Hazard Detection Unit logic
  assign lw_stall = ID_EX_memtoreg && ((ID_EX_rd == IF_ID_instr[19:15]) || (ID_EX_rd == IF_ID_instr[24:20]));
  
  //Stage 1 - IF
  assign pc_plus4 = pc_current + 32'd4;
  assign pc_target = pc_current + imm;
  
  assign pc_next = (jalr) ? jalr_target : 
                   (jump || decode_pcsrc) ? ID_pc_target : 
                                            pc_plus4;
  
  pc pc1(
    .clk(clk), 
    .rstn(rstn), 
    .en(!lw_stall), 
    .pc_next(pc_next), 
    .pc_current(pc_current)
  );
  
  instruction_mem im1(
    .address(pc_current), 
    .instr(instr)
  );
  
  //Stage 1 - 2
  always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      IF_ID_pc <= 32'b0;
      IF_ID_instr <= 32'b0;
    end
    else if (decode_pcsrc || jump) begin
      IF_ID_pc    <= 32'b0;
      IF_ID_instr <= 32'b0; // Overwrite the trapped sequential instruction with a NOP
    end
    else if(!lw_stall) begin
      IF_ID_pc <= pc_current;
      IF_ID_instr <= instr;
    end
  end
  
  //Stage 2 - ID
  imm_gen imm1(
    .instr(IF_ID_instr), 
    .imm(imm)
  );
  
  control_unit cu1(
    .opcode(IF_ID_instr[6:0]), 
    .funct3(IF_ID_instr[14:12]), 
    .funct7_5(IF_ID_instr[30]), 
    .regwrite(regwrite), 
    .memwrite(memwrite), 
    .ALUsrcb_sel(ALU_srcb_sel), 
    .MemtoReg(memtoreg), 
    .branch(branch), 
    .jump(jump), 
    .jalr(jalr),
    .ALUcontrol(ALUcontrol)
  );
  
  wire [31:0] actual_rd1 = ((ID_EX_rd == IF_ID_instr[19:15]) && ID_EX_regwrite) ? alu_result : rd1;
  wire [31:0] actual_rd2 = ((ID_EX_rd == IF_ID_instr[24:20]) && ID_EX_regwrite) ? alu_result : rd2;
  
  reg take_branch;
  always @(*) begin
    case (IF_ID_instr[14:12]) 
      3'b000:  take_branch = (actual_rd1 == actual_rd2);  // BEQ
      3'b001:  take_branch = (actual_rd1 != actual_rd2);  // BNE
      3'b100:  take_branch = ($signed(actual_rd1) < $signed(actual_rd2));  // BLT
      3'b101:  take_branch = ($signed(actual_rd1) >= $signed(actual_rd2)); // BGE
      3'b110:  take_branch = (actual_rd1 < actual_rd2);  // BLTU
      3'b111:  take_branch = (actual_rd1 >= actual_rd2);  // BGEU
      default: take_branch = 1'b0;
    endcase
  end
  
  assign decode_pcsrc = (branch === 1'b1) && take_branch;
  
  assign ID_pc_target = IF_ID_pc + imm;
  
  //Stage 2 - 3
  always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      ID_EX_instr        <= 32'd0;
      ID_EX_pc           <= 32'b0;
      ID_EX_rd1          <= 32'b0;
      ID_EX_rd2          <= 32'b0;
      ID_EX_imm          <= 32'b0;
      ID_EX_rd           <= 5'b0;
      ID_EX_ALU_srcb_sel <= 2'b0;
      ID_EX_ALUcontrol   <=4'b0;
      ID_EX_memwrite     <= 1'b0;
      ID_EX_memtoreg     <= 1'b0;
      ID_EX_regwrite     <= 1'b0;
      ID_EX_jump         <= 1'b0;
      ID_EX_branch       <= 1'b0;
      ID_EX_pc_plus4     <= 32'b0;
    end
    else if (lw_stall) begin
      ID_EX_instr     <= 32'd0; // Structural NOP
      ID_EX_rd        <= 5'b0;
      ID_EX_memwrite  <= 1'b0;  // Turn off side-effects
      ID_EX_memtoreg  <= 1'b0;
      ID_EX_regwrite  <= 1'b0;  // Turn off register file writes
      ID_EX_jump      <= 1'b0;
      ID_EX_branch    <= 1'b0;
      ID_EX_ALUcontrol<= 4'b0;
    end
    else begin
      ID_EX_instr        <= IF_ID_instr;
      ID_EX_pc           <= IF_ID_pc;
      ID_EX_rd1          <= actual_rd1;
      ID_EX_rd2          <= actual_rd2;
      ID_EX_imm          <= imm;
      if (regwrite) begin
        ID_EX_rd <= IF_ID_instr[11:7];
      end else begin
        ID_EX_rd <= 5'b00000; // Force to x0 so downstream stages never overwrite random registers
      end
      ID_EX_ALU_srcb_sel <= ALU_srcb_sel;
      ID_EX_ALUcontrol   <=ALUcontrol;
      ID_EX_memwrite     <= memwrite;
      ID_EX_memtoreg     <= memtoreg;
      ID_EX_regwrite     <= regwrite;
      ID_EX_jump         <= jump;
      ID_EX_branch       <= branch;
      ID_EX_pc_plus4     <= IF_ID_pc + 32'd4;
    end
  end
  
  //Stage 3 - EX
  assign EX_pc_target = ID_EX_pc + ID_EX_imm;
  assign pcsrc = ID_EX_branch & (alu_zero === 1'b1);
  
  assign alu_srcb = (ID_EX_ALU_srcb_sel == 2'b01) ? ID_EX_imm : 
                    (ID_EX_ALU_srcb_sel == 2'b10) ? 32'd4 : intermediate_operand_b;
  
  alu alu1(
    .A(alu_operand_a), 
    .B(alu_srcb), 
    .ALUcontrol(ID_EX_ALUcontrol), 
    .result(alu_result), 
    .zero(alu_zero)
  );
  
  // Forwarding Unit Logic Block
  always @(*) begin
    ForwardA = 2'b00; 
    ForwardB = 2'b00;
    
    if (EX_MEM_regwrite && (EX_MEM_rd != 5'b0) && (EX_MEM_rd == ID_EX_instr[19:15])) begin
      ForwardA = 2'b10;
    end
    if (EX_MEM_regwrite && (EX_MEM_rd != 5'b0) && (EX_MEM_rd == ID_EX_instr[24:20])) begin
      ForwardB = 2'b10;
    end
    
    if (MEM_WB_regwrite && (MEM_WB_rd != 5'b0) && 
         !(EX_MEM_regwrite && (EX_MEM_rd != 5'b0) && (EX_MEM_rd == ID_EX_instr[19:15])) &&
          (MEM_WB_rd == ID_EX_instr[19:15])) begin
      ForwardA = 2'b01;
    end
    if (MEM_WB_regwrite && (MEM_WB_rd != 5'b0) && 
         !(EX_MEM_regwrite && (EX_MEM_rd != 5'b0) && (EX_MEM_rd == ID_EX_rd)) && 
          (MEM_WB_rd == ID_EX_instr[24:20])) begin
      ForwardB = 2'b01;
    end
  end
  
  // Execution Stage Bypass MUXes logic
  always @(*) begin
    case(ForwardA)
      2'b00:   alu_operand_a = ID_EX_rd1;
      2'b01:   alu_operand_a = final_write_back_data; 
      2'b10:   alu_operand_a = EX_MEM_alu_result;     
      default: alu_operand_a = ID_EX_rd1;
    endcase

    case(ForwardB)
      2'b00:   intermediate_operand_b = ID_EX_rd2;
      2'b01:   intermediate_operand_b = final_write_back_data; 
      2'b10:   intermediate_operand_b = EX_MEM_alu_result;     
      default: intermediate_operand_b = ID_EX_rd2;
    endcase
  end
  
  //Stage 3 - 4
  always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      EX_MEM_instr      <= 32'd0;
      EX_MEM_alu_result <= 32'd0;
      EX_MEM_write_data <= 32'd0;
      EX_MEM_rd         <= 5'd0;
      EX_MEM_memwrite   <= 1'b0;
      EX_MEM_memtoreg   <= 1'b0;
      EX_MEM_regwrite   <= 1'b0;
      EX_MEM_jump       <= 1'b0;
      EX_MEM_pc_plus4   <= 32'b0;
    end
    else begin
      EX_MEM_instr      <= ID_EX_instr;
      EX_MEM_alu_result <= alu_result;
      EX_MEM_write_data <= ID_EX_rd2;
      EX_MEM_rd         <= ID_EX_rd;
      EX_MEM_memwrite   <= ID_EX_memwrite;
      EX_MEM_memtoreg   <= ID_EX_memtoreg;
      EX_MEM_regwrite   <= ID_EX_regwrite;
      EX_MEM_jump       <= ID_EX_jump;
      EX_MEM_pc_plus4   <= ID_EX_pc_plus4;
    end
  end
  
  //Stage 4 - MEM
  data_mem dm1(
    .clk(clk), 
    .memwrite(EX_MEM_memwrite), 
    .funct3(EX_MEM_instr[14:12]),  
    .address(EX_MEM_alu_result), 
    .write_data(EX_MEM_write_data), 
    .read_data(mem_read_data)
  );
  
  //Stage 4 - 5
  always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      MEM_WB_instr      <= 32'd0;
      MEM_WB_alu_result <= 32'd0;
      MEM_WB_read_data  <= 32'd0;
      MEM_WB_rd         <= 5'd0;
      MEM_WB_memtoreg   <= 1'b0;
      MEM_WB_regwrite   <= 1'b0;
      MEM_WB_jump       <= 1'b0;
      MEM_WB_pc_plus4   <= 32'b0;
    end
    else begin
      MEM_WB_instr      <= EX_MEM_instr;
      MEM_WB_alu_result <= EX_MEM_alu_result;
      MEM_WB_read_data  <= mem_read_data;
      MEM_WB_rd         <= EX_MEM_rd;
      MEM_WB_memtoreg   <= EX_MEM_memtoreg;
      MEM_WB_regwrite   <= EX_MEM_regwrite;
      MEM_WB_jump       <= EX_MEM_jump;
      MEM_WB_pc_plus4   <= EX_MEM_pc_plus4;
    end
  end
  
  //Stage 5 - WB
  reg_file rf1(
    .clk(clk), 
    .wr(MEM_WB_regwrite), 
    .rs1(IF_ID_instr[19:15]), 
    .rs2(IF_ID_instr[24:20]), 
    .rd(MEM_WB_rd), 
    .wd(final_write_back_data), 
    .rd1(rd1), 
    .rd2(rd2)
  );
  
  assign final_write_back_data = (MEM_WB_instr[6:0] == 7'b0110111) ? imm : 
                                 (MEM_WB_jump) ? MEM_WB_pc_plus4 : 
                                 (MEM_WB_memtoreg) ? MEM_WB_read_data : 
                                                     MEM_WB_alu_result;
  
endmodule
