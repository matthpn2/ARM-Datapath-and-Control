module arm( input  logic		 clk, reset,
		    output logic  [31:0] PC,
		    input  logic  [31:0] Instr,
   		    output logic 		 MemWrite,
		    output logic  [31:0] ALUResult, WriteData,
		    input  logic  [31:0] ReadData,
			output logic  [3:0]  ByteEn );
	
	logic [3:0]  ALUFlags;
	logic 		 RegWriteM, RegWriteW,
				 ALUSrc, MemtoRegW, MemtoRegE, PCSrcW,
				 BranchLinkEn, BranchTakenE, PCWrPendingF;
	logic [1:0]  RegSrc, ImmSrc;
	logic [3:0]  ALUControl;
	logic [4:0]  SHIFTControl;
	logic 		 carry_in;
	logic		 stallD, stallF, flushD, flushE;
	logic [1:0]  forwardAE, forwardBE;
	logic [4:0]  match;

	controller c(clk, reset, Instr[31:4], ALUFlags,
				 RegSrc, RegWriteM, RegWriteW, ImmSrc,
				 ALUSrc, ALUControl, SHIFTControl,
			     MemWrite, MemtoRegW, MemtoRegE, PCSrcW, carry_in, 
				 BranchLinkEn, BranchTakenE, PCWrPendingF, ByteEn,
				 stallD, flushD, flushE);
				 
	datapath dp(clk, reset,
				RegSrc, RegWriteW, ImmSrc,
				ALUSrc, ALUControl, SHIFTControl,
				MemtoRegW, PCSrcW,
				carry_in,
				ALUFlags, PC, Instr,
				ALUResult, WriteData, ReadData,
				BranchLinkEn, 
				forwardAE, forwardBE,
				stallD, stallF, flushD, flushE,
				BranchTakenE, match);

	hazardunit hu( match, PCSrcW, PCWrPendingF,
				   RegWriteM, RegWriteW, MemtoRegE, BranchTakenE, 
				   forwardAE, forwardBE,
				   stallD, stallF, flushD, flushE );			
endmodule