module shift( input  logic [31:0] rd2,				// rd2 from rf
			  input  logic [4:0]  SHIFTControl,	    // Instr[25:21] ( I + cmd )
			  input  logic [11:4] Instr,			// Instr[11:4]  ( Src2 )
			  input  logic [7:0]  RD3,			    // 8 LSB of RS
			  input  logic 		  carry_in,			// carry_in set from ALU
			  output logic [31:0] SHIFTResult,		// result output to mux ( choosing between immediate and shifted )
			  output logic        SHIFTFlag );		// shift flag output to ALU
	
	always_comb
	begin
		SHIFTResult = 32'd0;
		SHIFTFlag =  1'b0;
		
		if( SHIFTControl[3:0] != 4'b1101 ) begin							// output rd2 without shift
			SHIFTResult = rd2;
			SHIFTFlag = 1'b0;
		end else begin
		
			if( SHIFTControl[4] == 1'b1 || Instr[11:4] == 8'd0 ) begin		// MOVE (MOV)
				SHIFTResult = rd2;
				SHIFTFlag = 1'b0;
				
			end else if( SHIFTControl[4] == 1'b0 ) begin
				if( Instr[6:5] == 2'b00 && Instr[11:4] != 8'd0 ) begin		// LSL 
					if( Instr[4] == 1'b0 ) begin		// immediate register
						if( Instr[11:7] == 5'd0 ) begin
							SHIFTFlag = carry_in;
							SHIFTResult = rd2;
						end else begin
							SHIFTFlag = rd2[32 - Instr[11:7]];
							SHIFTResult = rd2 << Instr[11:7];
						end
					end else begin						// register shifted register
						if( RD3[7:0] == 8'd0 ) begin
							SHIFTFlag = carry_in;
							SHIFTResult = rd2;
						end else if( RD3[7:0] < 6'b100001 ) begin
							SHIFTFlag = rd2[32 - RD3[7:0]];
							SHIFTResult = rd2 << RD3[7:0];
						end else if( RD3[7:0] == 5'b10000 ) begin
							SHIFTFlag = rd2[0];
							SHIFTResult = 32'd0;
						end else begin
							SHIFTFlag = 1'b0;
							SHIFTResult = 32'd0;
						end
					end			
					
                end else if( Instr[6:5] == 2'b01 ) begin					// LSR
					if( Instr[4] == 1'b0 ) begin		// immediate register
						if( Instr[11:7] == 5'd0 ) begin
							SHIFTFlag = rd2[31];
							SHIFTResult = 32'd0;
						end else begin					
							SHIFTFlag = rd2[Instr[11:7] - 1]; 
							SHIFTResult = rd2 >> Instr[11:7];
						end
					end else begin						// register shifter register
						if( RD3[7:0] == 8'd0 ) begin
							SHIFTFlag = carry_in;
							SHIFTResult = rd2;
						end else if( RD3[7:0] < 6'b100001 ) begin
							SHIFTFlag = rd2[RD3[7:0] - 1];
							SHIFTResult	 = rd2 >> RD3[7:0];
						end else if( RD3[7:0] == 5'b10000 ) begin
							SHIFTFlag = rd2[31];
							SHIFTResult = 32'd0;
						end else begin
							SHIFTFlag = 1'b0;
							SHIFTResult = 32'd0;
						end
					end
				
				end else if (Instr[6:5] == 2'b10 ) begin					// ASR
					if( Instr[4] == 1'b0 ) begin			// immediate register
						if( Instr[11:7] == 5'd0 ) begin
							if( rd2[31] == 1'b0 ) begin
								SHIFTFlag = rd2[31];
								SHIFTResult = 32'd0;
							end else begin
								SHIFTFlag = rd2[31];
								SHIFTResult = 32'd1;
							end
						end else begin
							SHIFTFlag = rd2[Instr[11:7] - 1];
							SHIFTResult = rd2 >>> Instr[11:7];
						end									
					end else begin							// register shifted register
						if( RD3[7:0] == 8'd0 ) begin
							SHIFTFlag = carry_in;
							SHIFTResult = rd2;
						end else if( RD3[7:0] < 6'b100001 ) begin
							SHIFTFlag = rd2[RD3[7:0] - 1];
							SHIFTResult = rd2 >>> RD3[7:0];
						end else begin
							if( rd2[31] == 1'b0 ) begin
								SHIFTFlag = rd2[31];
								SHIFTResult = 32'd0;
							end else begin
								SHIFTFlag = rd2[31];
								SHIFTResult = 32'd1;
							end
						end
					end 
                
				end else if( Instr[6:5] == 2'b11 ) begin
					
					if( Instr[11:7] == 5'd0 && Instr[4] == 1'b0 ) begin 			 // RRX ( only immediate )
						SHIFTFlag = rd2[0];
						//SHIFTResult = { carry_in, rd2[31:1] };	// SHIFTResult[30:0] = rd2[31:1];
																// SHIFTResult[31] = carry_in;
						SHIFTResult = ( carry_in << 31 ) | ( rd2 >> 1 );
						
					end else if( Instr[11:7] != 5'd0 ) begin			 			 // ROR
						if( Instr[4] == 1'b0 ) begin			// immediate register
							SHIFTFlag = rd2[Instr[11:7] - 1];
							//SHIFTResult = rd2 >> Instr[11:7] | rd2 << (~Instr[11:7] + 1);					
							SHIFTResult = ( (rd2 >> Instr[11:7]) & ~(-1 << (32-Instr[11:7]))) | ( rd2 << (32-Instr[11:7]));
						end else begin							// register shifter register
							if( RD3[7:0] == 8'd0 ) begin
								SHIFTFlag = carry_in;
								SHIFTResult = rd2;
							end else if( RD3[4:0] == 5'd0 ) begin
								SHIFTFlag = rd2[31];
								SHIFTResult = rd2;
							end else begin
								SHIFTFlag = rd2[RD3[4:0] - 1];
								//SHIFTResult = rd2 >> RD3[4:0] | rd2 << (~RD3[4:0] + 1);
								SHIFTResult = ( (rd2 >> RD3[4:0]) & ~(-1 << (32-RD3[4:0]))) | ( rd2 << (32-RD3[4:0]));
							end
						end
					end
				end				
            end
        end
    end
	
endmodule
    