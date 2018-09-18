module hazardunit ( input  logic [4:0]  match,
					input  logic		PCSrcW, PCWrPendingF,
										RegWriteM, RegWriteW,
										MemtoRegE, BranchTakenE, 
					output logic [1:0]  forwardAE, forwardBE,
					output logic 		stallD, stallF,
										flushD, flushE );

	logic LDRstall;
		
	// SOLVING DATA HAZARDS WITH FORWARDING 
	assign forwardAE = ( match[3] & RegWriteM ) ? 2'b10 :	// SrcAE = ALUOutM
	                   ( match[1] & RegWriteW ) ? 2'b01 :	// SrcAE = ResultW
					                              2'b00 ;	// SrcAE  from regfile
														
    assign forwardBE = ( match[2] & RegWriteM ) ? 2'b10 :	// SrcBE = ALUOutM
	   				   ( match[0] & RegWriteW ) ? 2'b01 :	// SrcBE = ResultW
												  2'b00 ;	// SrcBE  from regfile	
		
	// SOLVING DATA HAZARDS WITH STALLS
	assign LDRstall    = ( match[4] & MemtoRegE );			// MemtoReg signal asserted for LDR instruction
	 
    // SOLVING CONTROL HAZARDS WITH STALLS    
	assign stallD = LDRstall;							    // stall decode if ldrstall
	assign stallF = LDRstall + PCWrPendingF;				// stall fetch if PCWrPendingF
	assign flushE = LDRstall + BranchTakenE;				// flush execute register if branch taken
	assign flushD = PCWrPendingF + PCSrcW + BranchTakenE;	// flush decode register if PCWrPendingF OR PC is written in writeback OR branch is taken.
		
endmodule		 