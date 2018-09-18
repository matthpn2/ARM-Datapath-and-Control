module dmem ( input  logic        clk, we,
			  input  logic [31:0] a,	// DataAdr
			  input  logic [31:0] wd,	// WriteData
			  output logic [31:0] rd,	// ReadData
			  input  logic [3:0]  ByteEn );
	
	// a[10:2] selects a 4-byte word
	// a[1:0] can choose a byte from the word			[1:0] [3:2] [5:4] [7:6]

	logic [7:0] ram_3[511:0];  
	logic [7:0] ram_2[511:0];  
	logic [7:0] ram_1[511:0];  
	logic [7:0] ram_0[511:0];  
	
	always_comb begin
		if (ByteEn == 4'b1111) assign rd = { ram_3[a[31:2]], ram_2[a[31:2]], ram_1[a[31:2]], ram_0[a[31:2]] }; // LDR ( load register word ) [4'b1111] loads word from memory | Rd ← Mem[Adr] ( Rd = data ) 		
		
		else if (ByteEn == 4'b0001) begin // LDRB ( load register unsigned byte ) [4'b0001] loads byte from memory and zero-extends byte to 32-bit word | Rd ← Mem[Adr]7:0 ( Rd = Memory[address,1] )
			case(a[1:0])
				2'b00: assign rd = {24'b0, ram_0[a[31:2]]};
				2'b01: assign rd = {24'b0, ram_1[a[31:2]]};
				2'b10: assign rd = {24'b0, ram_2[a[31:2]]};
				2'b11: assign rd = {24'b0, ram_3[a[31:2]]};
			endcase
			
		end else if (ByteEn == 4'b1001) begin // LDRSB ( load register signed byte ) [4'b1001] loads byte from memory and sign-extends byte to 32-bit word | Rd ← Mem[Adr]7:0 ( data = Memory[address,1] AND Rd = SignExtend(data) )										 
			case(a[1:0]) 					  
				2'b00: assign rd = {{24{ram_3[7]}}, ram_0[a[31:2]]};
				2'b01: assign rd = {{24{ram_3[7]}}, ram_1[a[31:2]]};
				2'b10: assign rd = {{24{ram_3[7]}}, ram_2[a[31:2]]};
				2'b11: assign rd = {{24{ram_3[7]}}, ram_3[a[31:2]]};
			endcase
			
		end else if (ByteEn == 4'b0011) begin // LDRH ( load register unsigned halfword ) [4'b0011] loads halfword from memory and zero-extends to 32-bit word | Rd ← Mem[Adr]15:0 ( Rd = ZeroExtend(data[15:0]) )	
			if (a[1] == 1'b0)	assign rd = {16'b0, ram_1[a[31:2]], ram_0[a[31:2]]};
			else 				assign rd = {16'b0, ram_3[a[31:2]], ram_2[a[31:2]]};
					
		end else if (ByteEn == 4'b1011) begin // LDRSH ( load signed halfword ) [4'b1011] loads halfword from memory and sign-extends halfword to 32-bit word | Rd ← Mem[Adr]15:0 ( data = Memory[address,2] AND Rd = SignExtend(data[15:0]) )
			if (a[1] == 1'b0)	assign rd = {{16{ram_3[7]}}, ram_1[a[31:2]], ram_0[a[31:2]]};
			else 				assign rd = {{16{ram_3[7]}}, ram_3[a[31:2]], ram_2[a[31:2]]};
		end
	end
	
	always_ff @( posedge clk )
		if (we) begin
			if (ByteEn == 4'b1111) begin // STR ( store register word ) [4'b1111] stores a word from a register to memory | Mem[Adr] ← Rd ( Memory[address,4] = Rd )
				{ram_3[a[31:2]],ram_2[a[31:2]],ram_1[a[31:2]],ram_0[a[31:2]]} <= wd;
			
			end else if (ByteEn == 4'b0001) begin // STRB ( store byte ) [4'b0001] stores a byte from the least significant byte of a register to memory | Mem[Adr] ← Rd7:0 ( Memory[address,1] = Rd[7:0] )
				case(a[1:0])
					2'b00: ram_0[a[31:2]] <= wd[7:0];
					2'b01: ram_1[a[31:2]] <= wd[7:0];
					2'b10: ram_2[a[31:2]] <= wd[7:0];
					2'b11: ram_3[a[31:2]] <= wd[7:0];
				endcase
			
			end else if (ByteEn == 4'b0011) begin // STRH ( store unsigned halfword ) [4'b0011] stores a halfword from the least significant halfword of a register to memory | Mem[Adr] ← Rd15:0 ( Memory[address,2] = Rd[15:0] )
				if (a[1] == 1'b0)	{ram_1[a[31:2]],ram_0[a[31:2]]} <= wd[15:0];
				else 				{ram_3[a[31:2]],ram_2[a[31:2]]} <= wd[15:0];
			end
		end
	
endmodule