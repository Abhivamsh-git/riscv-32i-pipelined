module riscv_pipeline_tb();
  
  reg clk;
  reg rstn;
  
  riscv_pipeline uut(.clk(clk), .rstn(rstn));
  
  always #5 clk = ~clk;
  
  initial begin
    fork
    forever begin
        @(posedge clk);
        #1; 
        $display("Time: %5t | IF_PC: 0x%h | ID_Instr: 0x%h | Stall: %b | EX_ALU: 0x%h | WB_Reg: x%0d | WB_Data: 0x%h | RegWrite: %b", 
                 $time, 
                 uut.pc_current,        
                 uut.IF_ID_instr,      
                 uut.lw_stall,         
                 uut.EX_MEM_alu_result,
                 uut.MEM_WB_rd,        
                 uut.final_write_back_data, 
                 uut.MEM_WB_regwrite   
        );
      end
    join_none
    
    clk = 0;
    rstn = 0;
    
    #15;
    rstn = 1; // Release reset
    
    #2500; // Run simulation
    
    #30;
    $display("=== SIMULATION COMPLETE ===");
    $display("Checking computed Fibonacci values inside Data Memory (dm1):");
    $display("Address 0x00 (Index 0): %d (Expected: 0)", uut.dm1.mem[0]);
    $display("Address 0x04 (Index 1): %d (Expected: 1)", uut.dm1.mem[1]);
    $display("Address 0x08 (Index 2): %d (Expected: 1)", uut.dm1.mem[2]);
    $display("Address 0x0C (Index 3): %d (Expected: 2)", uut.dm1.mem[3]);
    $display("Address 0x10 (Index 4): %d (Expected: 3)", uut.dm1.mem[4]);
    $display("Address 0x14 (Index 5): %d (Expected: 5)", uut.dm1.mem[5]);
    $display("Address 0x18 (Index 6): %d (Expected: 8)", uut.dm1.mem[6]);
    
    if (uut.dm1.mem[6] == 8) begin
      $display("\n>>> SUCCESS: Your Pipelined RISC-V Core successfully resolved hazards and passed! <<<");
    end else begin
      $display("\n>>> ERROR: Output mismatch. Review architectural connections. <<<");
    end
    
    $finish;
  end
  
endmodule
