
module instruction_register_cell (
	input 	clkIR,
			shIR,
			piData,
			preData,
	output reg dataNex
);
	
	reg s1;

	always @(clkIR) begin
		if (clkIR)
			s1 <= (shIR == 1'b0) ? piData : preData;
		else 
			dataNex <= s1;
	end
endmodule


module instruction_register #(
	parameter reg_len = 3,
	parameter instr_num = 5
) (
	input 	clkIR,
			upIR,
			shIR,
			tdi,
			reset,
	input [reg_len-1:0] piData,
	input [3:0] state,
	output tdo_mux,
	output reg [instr_num-1:0] instrB
);
	`include "constants.vh"

	wire [reg_len:0] data;
	reg [instr_num-1:0] instr_data;

	initial begin
		instr_data = 0;
	end

	assign data[0] = tdi;
	assign tdo_mux = data[reg_len];

	genvar i;
	generate
		for (i = 0; i < reg_len; i = i+1) begin
			instruction_register_cell ireg_i (
				.clkIR (clkIR),
				.shIR (shIR),
				.piData (piData[i]),
				.preData (data[i]),
				.dataNex (data[i+1])
			);
		end
	endgenerate

	always @(state) begin
		if (state == exit1ir_c) begin
			case (data[reg_len:1])
				3'b001 : instr_data <= idcode;
				3'b010 : instr_data <= sample_preload;
				3'b100 : instr_data <= extest;
				3'b101 : instr_data <= program;
				3'b110 : instr_data <= intest;
				default: instr_data <= bypass;
			endcase
		end
	end

	always @(reset, upIR) begin
		if (reset == 1'b0) begin
			instrB <= 0;
			instrB[0] <= 1'b1;
		end 
		else if (~upIR)	// clocked instruction bits output
			instrB <= instr_data;
	end
endmodule