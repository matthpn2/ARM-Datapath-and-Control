module flopfl #( parameter WIDTH = 8 )
			  ( input logic 	         clk, reset, flush,
			    input logic  [WIDTH-1:0] d,
				output logic [WIDTH-1:0] q );

	always_ff @( posedge clk, posedge reset )
	begin
		if (reset) 	    q <= 0;
		else begin 
			if (flush) q <= 0;
			else 			q <= d;
		end		
	end
endmodule