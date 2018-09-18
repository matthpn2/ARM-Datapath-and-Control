module controller( input  logic  		clk, reset,
				   input  logic [31:4]  InstrF,
				   input  logic [3:0]	ALUFlags,
				   output logic [1:0] 	RegSrcD,
				   output logic 		RegWriteM, RegWriteW,
				   output logic [1:0] 	ImmSrcD,
				   output logic 		ALUSrcE,
				   output logic  [3:0] 	ALUControlE,
				   output logic  [4:0]  SHIFTControlE,
				   output logic 		MemWriteM, MemtoRegW, MemtoRegE,
										PCSrcW,
				   output logic         carry_in,
				   output logic 	 	BranchLinkEnW, BranchTakenE, PCWrPendingF,
				   output logic	 [3:0]  ByteEnM,
				   input  logic         stallD, flushD, flushE );
				   
	logic [27:0] if_id_regin, if_id_regout;
	logic [29:0] id_ex_regin, id_ex_regout;
	logic [8:0]  ex_mem_regin, ex_mem_regout;
	logic [3:0]  mem_wb_regin, mem_wb_regout;
	logic [4:0]  SHIFTControlD;
	logic [3:0]  ALUControlD, ByteEnD, Flags;
	logic [1:0]	 FlagWriteD, FlagWrite;
	logic		 PCSrcD, RegWriteD, MemWriteD,
				 MemtoRegD, ALUSrcD, BranchLinkEnD, BranchD,
				 CondEx, RegWriteE, MemWriteE, PCSrcE;
				 
	// IF | ID register logic
	assign if_id_regin = { InstrF };
	flopflenr  #(28) if_id_reg( clk, reset, ~stallD, flushD, if_id_regin, if_id_regout ); // InstrF = if_id_regin[27:0]
	
	decoder dec( if_id_regout[23:22], if_id_regout[21:16], if_id_regout[11:8], if_id_regout[3:0],
				 FlagWriteD, PCSrcD, RegWriteD, MemWriteD,
				 MemtoRegD, ALUSrcD, ImmSrcD, RegSrcD, ALUControlD,	// ImmSrc to EXTEND REG and RegSrc to MULTIPLEXER
				 SHIFTControlD, BranchLinkEnD, ByteEnD, BranchD );	

	// ID | EX register logic
	assign id_ex_regin = { Flags, PCSrcD, RegWriteD, MemtoRegD, MemWriteD, ALUControlD, BranchLinkEnD, ByteEnD, BranchD, ALUSrcD, SHIFTControlD, FlagWriteD, if_id_regin[27:24] };
	flopfl #(30) id_ex_reg( clk, reset, flushE, id_ex_regin, id_ex_regout );	// FlagsE			= id_ex_regout[29:26]
																				// PCSrcE			= id_ex_regout[25]
																				// RegWriteE		= id_ex_regout[24]
																				// MemtoRegE		= id_ex_regout[23]
																				// MemWriteE		= id_ex_regout[22]
																				// ALUControlE		= id_ex_regout[21:18]
																				// BranchLinkEnE    = id_ex_regout[17]
																				// ByteEnE			= id_ex_regout[16:13]
																				// BranchE			= id_ex_regout[12]
																				// ALUSrcE			= id_ex_regout[11]
																				// SHIFTControlE	= id_ex_regout[10:6]
																				// FlagWE			= id_ex_regout[5:4]
																				// CondE 			= id_ex_regout[3:0]
		
	flopenr #(2)flagreg1( clk, reset, FlagWrite[1], ALUFlags[3:2], Flags[3:2] );
	flopenr #(2)flagreg0( clk, reset, FlagWrite[0], ALUFlags[1:0], Flags[1:0] );

	condcheck cc( id_ex_regout[3:0], id_ex_regout[29:26], CondEx );
	assign FlagWrite  		= id_ex_regout[5:4] & {2{CondEx}};
	assign RegWriteE  		= id_ex_regout[24]  & CondEx;
	assign MemWriteE  		= id_ex_regout[22]  & CondEx;
	assign PCSrcE     		= id_ex_regout[25]  & CondEx;
	assign BranchTakenE    	= id_ex_regout[12]  & CondEx;
	
	assign carry_in      = id_ex_regout[27];			// carry_in to ALU | SHIFT REG
	assign ALUSrcE 		 = id_ex_regout[11];			// ALUSrc to MULTIPLEXER
	assign ALUControlE	 = id_ex_regout[21:18];			// ALUControl to ALU REG
	assign SHIFTControlE = id_ex_regout[10:6];			// SHIFTControl to SHIFT REG		
	
	assign MemtoRegE    = id_ex_regout[23]; 		// MemtoRegE to HAZARD
	
	// EX | MEM register logic 
	assign ex_mem_regin = { id_ex_regout[17], id_ex_regout[16:13], PCSrcE, RegWriteE, id_ex_regout[23], MemWriteE };
	flopr #(9) ex_mem_reg( clk, reset, ex_mem_regin, ex_mem_regout );  // BranchLinkEnM = ex_mem_regout[8]
																	   // ByteEnM       = ex_mem_regout[7:4]
																	   // PCSrcM 	    = ex_mem_regout[3]
																	   // RegWriteM     = ex_mem_regout[2]
																	   // MemtoRegM     = ex_mem_regout[1]
																	   // MemWriteM     = ex_mem_regout[0]
    assign ByteEnM	 = ex_mem_regout[7:4];				// ByteEn   to DATA	MEMORY
	assign MemWriteM = ex_mem_regout[0]; 				// MemWrite to DATA MEMORY			

	assign RegWriteM    = ex_mem_regout[2];			// RegWriteM to HAZARD UNIT
																	   
	// MEM | WB register logic
	assign mem_wb_regin = { ex_mem_regout[8], ex_mem_regout[3], ex_mem_regout[2], ex_mem_regout[0] }; 
	flopr #(4) mem_wb_reg( clk, reset, mem_wb_regin, mem_wb_regout ); // BranchLinkEnW  = mem_wb_regout[3]	
																	  // PCSrcW		 	= mem_wb_regout[2]
																	  // RegWriteW 	 	= mem_wb_regout[1]
																	  // MemtoRegW 	 	= mem_wb_regout[0]
    assign BranchLinkEnW = mem_wb_regout[3];					// BranchLinkEn to REGISTER FILE	
    assign PCSrcW 		 = mem_wb_regout[2];					// PCSrc to MULTIPLEXER before PC
    assign RegWriteW     = mem_wb_regout[1];					// RegWriteW to REGISTER FILE AND HAZARD UNIT
	assign MemtoRegW     = mem_wb_regout[0];					// MemtoRegW to MULTIPLEXER 
																						  
	assign PCWrPendingF = PCSrcD + PCSrcE + ex_mem_regout[3]; 	// PCWrPendingF = 1 if write to PC in decode, execute or memory 
																						
endmodule

