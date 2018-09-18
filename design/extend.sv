module extend( input logic  [23:0] Instr,
		       input logic  [1:0]  ImmSrc,
			   output logic [31:0] ExtImm );
			   
    logic [4:0] rot;
	assign rot = Instr[11:8] << 1;
	
	always_comb
		case(ImmSrc)
					 // 8-bit unsigned immediate
			2'b00:   if(rot == 5'b00000) ExtImm = {24'b0, Instr[7:0]};
					 else ExtImm = Instr[7:0] >> rot | Instr[7:0] << (~rot + 5'b00001);
			
					 // 12-bit unsigned immediate
			2'b01:   ExtImm = {20'b0, Instr[11:0]};
			
					 // 24-bit two's complement shifted branch
			2'b10:   ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00};
			
			default: ExtImm = 32'bx; // undefined
			
		endcase
		
endmodule