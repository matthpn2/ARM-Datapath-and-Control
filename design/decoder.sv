module decoder( input  logic [1:0] Op,
			    input  logic [5:0] Funct,
			    input  logic [3:0] Rd,
				input  logic [3:0] Em,
			    output logic [1:0] FlagW,
			    output logic 	   PCS, RegW, MemW,
			    output logic       MemtoReg, ALUSrc,
			    output logic [1:0] ImmSrc, RegSrc, 
				output logic [3:0] ALUControl,
				output logic [4:0] SHIFTControl,
				output logic 	   BranchLinkEn,
				output logic [3:0] ByteEn,
				output logic       BranchD );				

	logic [14:0] controls;
	logic 		 Branch, ALUOp;
	
	// Main Decoder
	always_comb
		casex(Op)
								
			2'b00: if ({Funct[5], Em[3], Em[0]} == 3'b011) begin
					   if (Funct[0]) begin
						   if (Em[2:1] == 2'b01)           controls = 15'b000111100000011; // LDRH ( load unsigned halfword ) [4'b0011]										 
				           else if (Em[2:1] == 2'b10)      controls = 15'b000111100001001; // LDRSB ( load signed byte ) [4'b1001]										
						   else if (Em[2:1] == 2'b11) 	   controls = 15'b000111100001011; // LDRSH ( load signed halfword ) [4'b1011]
				       end else if (Em[2:1] == 2'b01) 	   controls = 15'b100111010000011; // STRH ( store unsigned byte ) [4'b0011]
				   end else begin
					   if (Funct[5]) controls = 15'b000010100100000; // Data-processing immediate
					   else          controls = 15'b000000100100000; // Data-processing register
				   end
				 
			2'b01: if (Funct[0]) begin						 
			           if(Funct[2]) controls = 15'b000111100000001; // LDRB ( load byte ) [4'b0001]
					   else   		controls = 15'b000111100001111;	// LDR ( load word ) [4'b1111]			   								
				   end else begin					    
					   if(Funct[2]) controls = 15'b100111010000001;	// STRB ( store byte ) [4'b0001]							
					   else 	    controls = 15'b100111010001111; // STR ( store word ) [4'b1111]			
				   end
								
			2'b10: if (Funct[4]) controls = 15'b011010101010000; // BL
				   else 		 controls = 15'b011010001000000; // B
				
			default: 		  	  controls = 15'bx; // Unimplemented
		endcase
	
	assign {RegSrc, ImmSrc, ALUSrc, MemtoReg,
		RegW, MemW, Branch, ALUOp, BranchLinkEn, ByteEn} = controls;
		
	// ALU Decoder
	always_comb
	if (ALUOp) begin // which DP Instr?
		ALUControl = Funct[4:1];
		SHIFTControl = Funct[5:1];
	
		// update flags if S bit is set (C & V only for arith)
		FlagW[1] 		= Funct[0];
		FlagW[0]		= Funct[0] &
			( ALUControl == 4'b0010 | ALUControl == 4'b0011 | ALUControl == 4'b0100 | ALUControl == 4'b0101 |
 			  ALUControl == 4'b0110 | ALUControl == 4'b0111 | ALUControl == 4'b1010 | ALUControl == 4'b1011 );
			  
	end else begin
		ALUControl = 4'b0100; // add for non-DP instructions
		FlagW 	   = 2'b00; // don't update Flags
	end
	
	// PC Logic
	assign PCS 		= ((Rd == 4'b1111) & RegW) | Branch;
	assign BranchD  = Branch;
	
endmodule