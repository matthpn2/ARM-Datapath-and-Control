module mux3 #( parameter WIDTH = 8 )
			 ( input  logic [WIDTH-1:0] d0, d1, d2,
			   input  logic [1:0]		sel,
			   output logic [WIDTH-1:0] out );
				  
	assign out = ( sel == 2'b00 ) ? d0 :
				 ( sel == 2'b01 ) ? d1 :
				 ( sel == 2'b10 ) ? d2 :
									32'bx;
									
endmodule	