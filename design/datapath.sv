module datapath( input  logic 	     clk, reset,
				 input  logic [1:0]  RegSrc,
				 input  logic 	     RegWrite,
				 input  logic [1:0]  ImmSrc,
				 input  logic 	     ALUSrc,
				 input  logic [3:0]  ALUControl,
				 input  logic [4:0]  SHIFTControl,
				 input  logic 	     MemtoRegW,
				 input  logic 	     PCSrcW,
				 input  logic		 carry_in,
				 output logic [3:0]  ALUFlags,
				 output logic [31:0] PC,
				 input  logic [31:0] InstrF,
				 output logic [31:0] ALUResult, WriteData,
				 input  logic [31:0] ReadData,
				 input  logic        BranchLinkEn, 
				 input  logic [1:0]  forwardAE, forwardBE,
				 input  logic        stallD, stallF, flushD, flushE,
				 input  logic        BranchTakenE, 
				 output logic [4:0]  match );
				 
	logic [179:0] id_ex_regin, id_ex_regout;
	logic [99:0]  ex_mem_regin, ex_mem_regout,
				  mem_wb_regin, mem_wb_regout;		
	logic [63:0]  if_id_regin, if_id_regout;
	logic [31:0]  PCNext, PCPlus4,
				  ExtImm, SrcA, SrcB, Result,
				  ALUResultE, WriteDataD, WriteDataE,
				  R14, RD3, SHIFTResult,
				  ALURes, WriteD, PCNextF,
				  SrcAE, SrcBE;
	logic [3:0]   WA3W, WA3E, WA3M;
	logic [3:0]   RA1D, RA2D, RA3, WA3, RA1E, RA2E;
	logic 		  SHIFTFlag,
				  match_1e_m, match_2e_m, 
				  match_1e_w, match_2e_w, match_12d_e;

	assign RA3 = if_id_regout[11:8];

	// next PC logic
	mux2  #(32) pcmux(PCPlus4, Result, PCSrcW, PCNext);
	mux2  #(32) brmux(PCNext, ALUResultE, BranchTakenE, PCNextF );	// add branch multiplexer before PC register to select BTA ( branch destination ) from ALUResultE
	flopenr #(32) pcreg(clk, reset, ~stallF, PCNextF, PC);			// add enable input ( EN ) to fetch register
	adder #(32) pcadd1(PC, 32'b100, PCPlus4);
	
	// IF | ID register logic 
	assign if_id_regin = { PCPlus4, InstrF };
	flopflenr #(64) if_id_reg( clk, reset, ~stallD, flushD, if_id_regin, if_id_regout ); // PCPlus4D = if_id_regout[63:32] 
																						 // InstrD 	 = if_id_regout[31:0]
																	// add enable input ( EN ) to decode pipeline registers
	// register file logic
	mux2 #(4)  ra1mux(if_id_regout[19:16], 4'b1111, RegSrc[0], RA1D);
	mux2 #(4)  ra2mux(if_id_regout[3:0], if_id_regout[15:12], RegSrc[1], RA2D);
	mux2 #(4)  ra3mux(WA3W, 4'b1110, BranchLinkEn, WA3);	
	mux2 #(32) wd3mux(Result, mem_wb_regout[99:68], BranchLinkEn, R14);					
	regfile rf(clk, RegWrite, RA1D, RA2D, RA3,
			   WA3, R14, PCPlus4,											
			   SrcA, WriteDataD, RD3);
	mux2 #(32) resmux(mem_wb_regout[31:0], mem_wb_regout[63:32], MemtoRegW, Result);
	extend ext(if_id_regout[23:0], ImmSrc, ExtImm);	
	
	// ID | EX register logic
	assign id_ex_regin = { if_id_regout[63:32], RA1D, RA2D, if_id_regout[15:12], if_id_regout[11:4], SrcA, WriteDataD, RD3, ExtImm };
									// add synchronous reset/clear input ( CLR ) to execute pipeline register
	flopfl #(180) id_ex_reg( clk, reset, flushE, id_ex_regin, id_ex_regout );  // PCPlus4E      = id_ex_regout[179:148]
																			   // RA1E			= id_ex_regout[147:144]
																			   // RA2E			= id_ex_regout[143:140]
																			   // InstrE[15:12]	= id_ex_regout[139:136]
																			   // InstrE[11:4]  = id_ex_regout[135:128]
																			   // SrcAE 	    = id_ex_regout[127:96]
																			   // WriteDataE	= id_ex_regout[95:64]
																			   // RD3E			= id_ex_regout[63:32]
																			   // ExtImmE		= id_ex_regout[31:0]

	// add two multiplexers in front of ALU to select operand from RF or memory or writeback stage ( ALUoutM or ResultW )
	mux3 #(32) srcAEmux( id_ex_regout[127:96], Result, ex_mem_regout[63:32], forwardAE, SrcAE );
	mux3 #(32) srcBEmux( id_ex_regout[95:64], Result, ex_mem_regout[63:32], forwardBE, SrcBE );	
	
	// shift logic
	shift shift(SrcBE, SHIFTControl, id_ex_regout[135:128], id_ex_regout[39:32], carry_in, SHIFTResult, SHIFTFlag);
		
	// ALU logic
	mux2 #(32) srcbmux(SHIFTResult, id_ex_regout[31:0], ALUSrc, SrcB);
	alu alu(SrcAE, SrcB, ALUControl, carry_in, SHIFTFlag, ALUResultE, ALUFlags);
	
	// EX | MEM register logic 
	assign ex_mem_regin = { id_ex_regout[179:148], id_ex_regout[139:136], ALUResultE, id_ex_regout[95:64] };
	flopr #(100) ex_mem_reg( clk, reset, ex_mem_regin, ex_mem_regout ); // PCPlus4M     = ex_mem_regout[99:68]
																		// Instr[15:12]	= ex_mem_regout[67:64]
																	    // ALUResultM	= ex_mem_regout[63:32]
																	    // WriteDataM 	= ex_mem_regout[31:0]
	assign ALUResult = ex_mem_regout[63:32]; 
	assign WriteData = ex_mem_regout[31:0];
    	
	// MEM | WB register logic 
	assign mem_wb_regin = { ex_mem_regout[99:68], ex_mem_regout[67:64], ReadData, ex_mem_regout[63:32] };	
	flopr #(100) mem_wb_reg( clk, reset, mem_wb_regin, mem_wb_regout ); // PCPlus4W     = mem_wb_regout[99:68]
																		// Instr[15:12]	= mem_wb_regout[67:64]
																	    // ReadDataW	= mem_wb_regout[63:32]
																	    // ALUResultW	= mem_wb_regout[31:0]
																	   
    assign RA1E = id_ex_regout[147:144]	;		
	assign RA2E = id_ex_regout[143:140];
	assign WA3E = id_ex_regout[139:136];
	assign WA3M = ex_mem_regout[67:64];
	assign WA3W = mem_wb_regout[67:64];
	
	
	assign match_1e_m = ( RA1E == WA3M );   
	assign match_2e_m = ( RA2E == WA3M );   
	assign match_1e_w = ( RA1E == WA3W );   
	assign match_2e_w = ( RA2E == WA3W );   
	assign match_12d_e = ( RA1D == WA3E ) + ( RA2D == WA3E );	
	assign match = { match_12d_e, match_1e_m, match_2e_m, match_1e_w, match_2e_w };
	
endmodule