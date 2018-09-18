module top(
			input  logic 	    clk, reset,
			output logic [31:0] DataAdr,
			output logic [31:0] WriteData,
			output logic 	    MemWrite
		  );

    logic [31:0] PC, Instr, ReadData;
	logic [3:0]  ByteEn;

    // instantiate processor and memories
    arm  arm(clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData, ByteEn);
    imem imem(PC, Instr);
    dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData, ByteEn);
endmodule
