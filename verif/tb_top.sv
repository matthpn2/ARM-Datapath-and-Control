module tb_top();
    logic clk;
    logic reset;
    logic [31:0] DataAdr;
    logic [31:0] WriteData;
    logic MemWrite;


    // instantiate device to be tested
    top dut(clk, reset, DataAdr, WriteData, MemWrite);


    // initialize test
    initial
    begin
        reset <= 1; # 22; reset <= 0;
    end

    // generate clock to sequence tests
    always
    begin
        clk <= 1; # 5; clk <= 0; # 5;
    end

	always @(negedge clk)
    begin
        if(MemWrite) begin
            if(DataAdr === 252 &  WriteData === 9) // ALU test
								// change to 3 for BONUS test
								// change to 22 for DATA PROCESSING test
								// change to 5 for LDR-STR test
								// change to 2 for REGRESSION test
            begin
                $display("Simulation succeeded");
				$display("your score is %d out of 9", WriteData);
                $stop;
            end 
            else //if (DataAdr !== 96) 
            begin
                $display("Simulation failed");
                $display("your score is %d out of 9", WriteData);
		$stop;
            end
        end
    end
	
    // Limits sim time to 1600ns
    initial begin
    #1600;
    $finish;
    end
endmodule
