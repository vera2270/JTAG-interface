
module reg_bypass (
	input	data_in,
			shiftDR,
			clkDR,
	output reg data_out
);

	wire s1 = data_in & shiftDR;

	always @(posedge clkDR) begin
		data_out <= s1;
	end
endmodule


module id_cell (
	input 	clkDR,
			shiftDR,
			id_code_bit,
			prevCell,
	output reg nextCell
);

	wire s1;

	assign s1 = (shiftDR == 1'b0) ? id_code_bit : prevCell;

	always @(posedge clkDR) begin
		nextCell <= s1;
	end	
endmodule


// MSB											    LSB
//  31	   28 27         12 11                    1  0
// | version | part number | manufacturer identity | 1 |
//   4 bits      16 bits           11 bits

module reg_id (
	input 	clkDR,
			shiftDR,
	output 	data_out
);
	`include "constants.vh"

	wire [32:0] data;

	assign data[32] = 1'b0;
	assign data_out = data[0];

	genvar i;

	generate
		for (i = 0; i < 32 ; i = i+1) begin
			id_cell id_cell_i (
				.clkDR (clkDR),
				.shiftDR (shiftDR),
				.id_code_bit (id_data[i]),
				.prevCell (data[i+1]),
				.nextCell (data[i])
			);
		end
	endgenerate
endmodule


module bsr_cell ( // BC_1 with reset and enable
	input 	reset,
			enableIn,
			enableOut,
			mode,
			clkDR,
			shiftDR,
			updateDR,
			data_pin,
			prevCell,
	output 	nextCell,
			data_pout
);

	wire s1;
	reg s2;
	reg s3;

	initial begin
		s2 = 1'b0;
		s3 = 1'b0;
	end

	assign nextCell = (reset == 1'b1) ? s2 : 1'b0;

	// select input for shift register stage
	assign s1 = (shiftDR == 1'b0 & enableIn == 1'b1) ? data_pin : prevCell;

	// select input for parallel output
	assign data_pout = 	(mode == 1'b0 & enableOut == 1'b1) ? data_pin : 
						(mode == 1'b1 & enableOut == 1'b1) ? s3 : 1'b0;

	always @(negedge reset, negedge clkDR, posedge updateDR) begin
		if (reset == 1'b0) begin
			s2 <= 1'b0;
			s3 <= 1'b0;
		end
		else if (~clkDR)
			s2 <= s1;
		else if (updateDR)
			s3 <= s2;
	end
endmodule


/* module bsr_cell_io ( // BC_2 control and BC_7 data for bidirectional pin
	input 	output_en,
			output_data,
			prevCell,
			mode_2,
			mode_5,
			mode_6,
			shiftDR,
			clockDR,
			updateDR,
	output 	input_data,
			nextCell,
	inout 	system_pin
);
	
	reg c_en1, c_en2, c_en, c_in, c_next_Cell;
	reg d_out, d_out2, d_sel1, d_s1, d_s2, d_s3, d_sys_in;

	// control cell
	assign c_en1 = (mode_5 == 1'b0) ? output_en : c_en2;
	assign c_en  = c_en1 & mode_6;
	assign c_in  = (shiftDR == 1'b0) ? c_en1 : d_s3;

	assign nextCell = c_next_Cell;
	always @(posedge clockDR) begin
		c_next_Cell <= c_in;
	end

	always @(posedge updateDR) begin
		c_en2 <= c_next_Cell;
	end

	// combined input and output cell
	assign d_out	= (mode_5 == 1'b0) ? output_data : d_out2;
	assign d_sys_in = (mode_2 == 1'b0) ? system_pin : d_out2;
	assign d_sel1	= c_en1 & ~mode_5;
	assign d_s1	= (d_sel1 == 1'b0) ? d_sys_in : d_out;
	assign d_s2	= (shiftDR == 1'b0) ? d_s1 : prevCell;

	always @(posedge clockDR) begin
		d_s3 <= d_s2;
	end

	always @(posedge updateDR) begin
		d_out2 <= d_s3;
	end

	assign input_data = d_sys_in;
	
	// enable output
	assign system_pin = (c_en == 1'b1) ? d_out : z;
endmodule */


module bsreg #(
	parameter len = 4
) (
	input 	tck,
			reset,
			enableIn,
			enableOut,
			mode,
			clkDR,
			shiftDR,
			updateDR,
			tdi,
	input [len-1:0] data_pin,
	output 	tdo,
	output [len-1:0] data_pout
);
	
	wire [len:0] data;

	assign data[0] = tdi;
	assign tdo = data[len];

	genvar i;
	generate
		for (i = 0; i < len; i= i+1) begin
			bsr_cell bsr_cell_i (
				.reset (reset),
				.enableIn (enableIn),
				.enableOut (enableOut),
				.mode (mode),
				.clkDR (clkDR),
				.shiftDR (shiftDR),
				.updateDR (updateDR),
				.data_pin (data_pin[i]),
				.prevCell (data[i]),
				.nextCell (data[i+1]),
				.data_pout (data_pout[i])
			);
		end
	endgenerate
endmodule