module alu( input  logic [31:0] SrcA, SrcB, 	// source a & b ( shifter op OR immediate )
			input  logic [3:0]  ALUControl, 	// alu op code (cmd) of Instr[24:21]
			input  logic		carry_in,		// carry in = previous set carry flag
			input  logic		SHIFTFlag,		// carry flag from shift
			output logic [31:0] ALUResult, 		// result produced and output
			output logic [3:0]  ALUFlags 		// N[3] negative = ALUResult[31]  
												// Z[2] zero = ALL of bits of ALUResult are 0 ( detected by N-bit NOR gate )
												// C[1] carry = adder produces carry out and ALU performing ADD or SUB
												// V[0] overflow = occurs when addition of two same signed numbers produces result with opposite sign
														// (1) ALU performing ADD or SUB
														// (2) SrcA and ALUResult have opposite signs, detected by XOR and XNOR gates
														// (3) either SrcA and SrcB have same sign and adder is performing ADD
																							// OR
															// either SrcA and SrcB have opposite sign and adder is performing SUB 
										);
		
	logic [31:0] temp_result;
	
	always_comb
	begin
		// default values to be overwritten, clears all values
		// thus preventing accidental creation of latches when NOT assigned
		ALUFlags = 4'd0; 		// 'd0;
		ALUResult = 32'd0;		// 'd0;
		
		case( ALUControl )
		
			4'b0000 : // AND 									OP RD <- RN & SO 					N Z C
			begin
				ALUResult = SrcA & SrcB;
				ALUFlags[3] = ALUResult[31];
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;
			end
			
			4'b0001 : // XOR (EOR)								OP RD <- RN ^ SO					N Z C
			begin
				ALUResult = SrcA ^ SrcB;
				ALUFlags[3] = ALUResult[31];
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;			
			end
			
			4'b0010 : // SUB									OP RD <- RN - SO 					N Z C V
			begin
				{ ALUFlags[1],ALUResult } = SrcA - SrcB; 		
				if( SrcA[31] & ~SrcB[31] & ~ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else if( ~SrcA[31] & SrcB[31] & ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[3] = ALUResult[31];
			end
			
			4'b0011 : // REVERSE SUB (RSB)						OP RD <- SO - RN 					N Z C V
			begin	
				{ ALUFlags[1],ALUResult } = SrcB - SrcA; 		
				if( SrcB[31] & ~SrcA[31] & ~ALUResult[31] ) begin		
					ALUFlags[0] = 1'b1;
				end else if( ~SrcB[31] & SrcA[31] & ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[3] = ALUResult[31];			
			end
			
			4'b0100 : // ADD									OP RD <- RN + SO 					N Z C V
			begin
				{ ALUFlags[1],ALUResult } = SrcA + SrcB;
				if( SrcA[31] & SrcB[31] & ~ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else if( ~SrcA[31] & ~SrcB[31] & ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[3] = ALUResult[31];
			end
			
			4'b0101 : // ADD WITH CARRY (ADC)					OP RD <- RN + SO + CF				N Z C V
			begin
				{ ALUFlags[1],ALUResult } = SrcA + SrcB + {31'd0,carry_in};
				if( SrcA[31] & SrcB[31] & ~ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else if( ~SrcA[31] & ~SrcB[31] & ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[3] = ALUResult[31];
			end
			
			4'b0110 : // SUB WITH CARRY (SBC)					OP RD <- RN - SO - NOT(CF)			N Z C V
			begin
				{ ALUFlags[1],ALUResult } = SrcA - SrcB - {31'd0,~carry_in};	
				if( SrcA[31] & ~SrcB[31] & ~ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else if( ~SrcA[31] & SrcB[31] & ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[3] = ALUResult[31];
			end		
			
			4'b0111 : // REVERSE SUB WITH CARRY (RSC)			OP RD <- SO - RN - NOT(CF)			N Z C V
			begin
				{ ALUFlags[1],ALUResult } = SrcB - SrcA - {31'd0,~carry_in};	
				if( SrcB[31] & ~SrcA[31] & ~ALUResult[31] ) begin		
					ALUFlags[0] = 1'b1;
				end else if( ~SrcB[31] & SrcA[31] & ALUResult[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[3] = ALUResult[31];				
			end
			
			4'b1000 : // TEST (TST)								FLAGS BASED ON RN & SO  			N Z C
			begin
				temp_result = SrcA & SrcB;
				ALUFlags[3] = temp_result[31];
				ALUFlags[2] = ~|temp_result;
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;
			end
			
			4'b1001 : // TEST EQUIVALENCE (TEQ)					FLAGS BASED ON RN ^ SO  			N Z C
			begin
				temp_result = SrcA ^ SrcB;
				ALUFlags[3] = temp_result[31];
				ALUFlags[2] = ~|temp_result;
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;			
			end
			
			4'b1010 : // COMPARE (CMP)							FLAGS BASED ON RN - SO  			N Z C V
			begin
				{ ALUFlags[1],temp_result } = SrcA - SrcB;		
				if( SrcA[31] & ~SrcB[31] & ~temp_result[31] ) begin
					ALUFlags[0] = 1'b1;
				end else if( ~SrcA[31] & SrcB[31] & temp_result[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|temp_result;
				ALUFlags[3] = temp_result[31];	
			end
			
			4'b1011 : // COMPARE NEGATIVE (CMN)					FLAGS BASED ON RN + SO  			N Z C V
			begin
				{ ALUFlags[1],temp_result } = SrcA + SrcB;
				if( SrcA[31] & SrcB[31] & ~temp_result[31] ) begin
					ALUFlags[0] = 1'b1;
				end else if( ~SrcA[31] & ~SrcB[31] & temp_result[31] ) begin
					ALUFlags[0] = 1'b1;
				end else begin
					ALUFlags[0] = 1'b0;
				end
				ALUFlags[2] = ~|temp_result;
				ALUFlags[3] = temp_result[31];
			end		
			
			4'b1100 : // OR (ORR)								OP RD <- RN | SO 					N Z C
			begin
				ALUResult = SrcA | SrcB;
			    ALUFlags[3] = ALUResult[31];
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;
			end
			
			4'b1101 : // SHIFTS																		N Z C
			begin
				ALUResult = SrcB;
				ALUFlags[3] = ALUResult[31];
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[1] = SHIFTFlag;
				ALUFlags[0] = 1'b0;
			end
			
			4'b1110 : // CLEAR (BIC)							OP RD <- RN & NOT(SO) 			 	N Z C
			begin
				ALUResult = SrcA & ~SrcB;
			    ALUFlags[3] = ALUResult[31];
				ALUFlags[2] = ~|ALUResult;
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;
			end
			
			4'b1111 : // NOT (MVN)								OP RD <- NOT(SO)					N Z C
			begin
				ALUResult = ~SrcB;
			    ALUFlags[3] = ALUResult[31];
				ALUFlags[2] = ~|ALUResult;	
				ALUFlags[1] = SHIFTFlag;						
				ALUFlags[0] = 1'b0;
			end
			
			default :
            begin
				ALUResult = 32'd0;
                ALUFlags = 4'd0;
			end
		endcase
	end
	
endmodule 