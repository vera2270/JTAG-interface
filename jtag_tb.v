`timescale 1ps/1ps
module jtag_tb;
	parameter instruction_len = 3;
	parameter pins_in_count = 4;
	parameter pins_out_count = 4;

	reg tck = 1'b1;
	reg tms = 1'b1;
	reg tdi = 1'b1;
	wire tdo;

	reg [pins_in_count-1:0] pins_in = 4'b0100;
	wire [pins_out_count-1:0] pins_out;
	wire [pins_in_count-1:0] logic_pins_in;
	reg [pins_out_count-1:0] logic_pins_out = 4'b0101;

	wire active;
	wire [31:0] config_data;
	wire config_strobe;

	tap tap_i (
		.tck(tck),
		.tms(tms),
		.tdi(tdi),
		.tdo(tdo),
		.pins_in(pins_in),
		.pins_out(pins_out),
		.logic_pins_in(logic_pins_in),
		.logic_pins_out(logic_pins_out),
		.active(active),
		.config_data(config_data),
		.config_strobe(config_strobe)
	);


	always #5000 tck = (tck === 1'b0);


	integer i, j, k;
	reg [15:0] send = 16'hFAB1;
	reg [31:0] sendex = 32'hFFFFFAB1;
    reg [15:0] endconf = 16'hFAB0;
	reg [7:0] bitstream[0:15];

	initial begin
		$dumpfile("jtag_tb.vcd");
		$dumpvars(0, jtag_tb);
		$readmemh("bitstream.hex", bitstream);
		// for (i = 0; i < 16; i = i+1) begin
		// 	for (j = 0; j < 8; j = j+1) begin
		// 		$display (bitstream[i][7-j]);
		// 	end
		// end
		repeat (3) @(posedge tck);
		@(negedge tck);
		// setup jtag
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//instruction preload
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//
		tms = 1'b1; // select DR
		@(negedge tck);

		// exec
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		// data
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0; // idle
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1; // reset
		@(negedge tck);

		/////////////////////////////////

		// setup jtag
		// tms = 1'b0;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//instruction extest
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//
		tms = 1'b1; // select DR
		@(negedge tck);

		// exec
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		// data
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0; // idle
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1; // reset
		@(negedge tck);

		////////////////////////////////////

		// setup jtag
		// tms = 1'b0;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//instruction idcode
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//
		tms = 1'b1; // select DR
		@(negedge tck);

		// exec
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		// data
		for (i = 0; i < 32; i = i+1) begin
			tdi = 1'b0;
			@(negedge tck);
		end
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0; // idle
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1; // reset
		@(negedge tck);

		/////////////////////////////////////////

		// setup jtag
		// tms = 1'b0;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//instruction intest
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//
		tms = 1'b1; // select DR
		@(negedge tck);

		// exec
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		// data
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0; // idle
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1; // reset
		@(negedge tck);

		/////////////////////////////////////////////

		// setup jtag
		// tms = 1'b0;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		// tms = 1'b1;
		// @(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//instruction program
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		// @(negedge tck);
		//
		// tms = 1'b1; // select DR
		for (i = 0; i < 4; i = i+1) begin
			for (j = 0; j < 4; j = j+1) begin
				for (k = 0; k < 8; k = k+1) begin
					tms = 1'b0;
					tdi = bitstream[4*i+j][7-k];
					if (8*j+k > 14)
						tms = send[31 - (8*j+k)];
					@(negedge tck);
				end
			end
		end
		tdi = 1'b1;
        for (i = 0; i < 16; i = i+1) begin
            tms = endconf[15-i];
            @(negedge tck);
        end
		tms = 1'b1;

		///////////////////////////////////////

		// setup jtag
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//instruction bypass
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		//
		tms = 1'b1; // select DR
		@(negedge tck);

		// exec
		tms = 1'b0;
		@(negedge tck);
		tms = 1'b0;
		@(negedge tck);
		// data
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		@(negedge tck);
		tdi = 1'b0;
		@(negedge tck);
		tdi = 1'b1;
		//
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b0; // idle
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1;
		@(negedge tck);
		tms = 1'b1; // reset
		@(negedge tck);

		repeat (10) @(posedge tck);

		$finish;
	end

endmodule