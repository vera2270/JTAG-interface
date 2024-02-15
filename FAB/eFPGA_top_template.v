module eFPGA_top (${uio_list}CLK, resetn, SelfWriteStrobe, SelfWriteData, Rx, ComActive, ReceiveLED, s_clk, s_data, tms, tdi, tdo);

	localparam include_eFPGA = 1;
	localparam NumberOfRows = ${NumberOfRows};
	localparam NumberOfCols = ${NumberOfCols};
	localparam FrameBitsPerRow = 32;
	localparam MaxFramesPerCol = 20;
	localparam desync_flag = 20;
	localparam FrameSelectWidth = 5;
	localparam RowSelectWidth = 5;

	input wire CLK; // This clock can go to the CPU (connects to the fabric LUT output flops
	input wire resetn; // active low async reset for all the config logic

	// CPU configuration port
	input wire SelfWriteStrobe; // must decode address and write enable
	input wire [32-1:0] SelfWriteData; // configuration data write port

	// UART configuration port
	input wire Rx;
	output wire ComActive;
	output wire ReceiveLED;

	// BitBang configuration port
	input wire s_clk;
	input wire s_data;

	// JTAG port
	input wire tms;
	input wire tdi;
	output wire tdo;
	input wire tck;

${uio_wires}

	// Signal declarations
	wire [(NumberOfRows*FrameBitsPerRow)-1:0] FrameRegister;
	wire [(MaxFramesPerCol*NumberOfCols)-1:0] FrameSelect;
	wire [(FrameBitsPerRow*(NumberOfRows+2))-1:0] FrameData;
	wire [FrameBitsPerRow-1:0] FrameAddressRegister;
	wire LongFrameStrobe;
	wire [31:0] LocalWriteData;
	wire LocalWriteStrobe;
	wire [RowSelectWidth-1:0] RowSelect;

	// JTAG related
	reg [3:0] pins_in = 0;
	wire [3:0] pins_out;
	wire [3:0] sys_pins_in;
	reg [3:0] sys_pins_out = 0;
	wire [31:0] JTAGWriteData;
	wire JTAGWriteStrobe;
	wire JTAGActive;

	tap Inst_jtag (
		.tck(tck),
		.tms(tms),
		.tdi(tdi),
		.tdo(tdo),
		.trst(resetn),
		.pins_in(pins_in),
		.pins_out(pins_out),
		.logic_pins_in(sys_pins_in),
		.logic_pins_out(sys_pins_out),
		.active(JTAGActive),
		.config_data(JTAGWriteData),
		.config_strobe(JTAGWriteStrobe)
	);

	Config Config_inst (
		.CLK(CLK),
		.resetn(resetn),
		.Rx(Rx),
		.ComActive(ComActive),
		.ReceiveLED(ReceiveLED),
		.s_clk(s_clk),
		.s_data(s_data),
		.SelfWriteData(SelfWriteData),
		.SelfWriteStrobe(SelfWriteStrobe),
		
		.ConfigWriteData(LocalWriteData),
		.ConfigWriteStrobe(LocalWriteStrobe),
		
		.FrameAddressRegister(FrameAddressRegister),
		.LongFrameStrobe(LongFrameStrobe),
		.RowSelect(RowSelect),

		.JTAGWriteData(JTAGWriteData),
		.JTAGWriteStrobe(JTAGWriteStrobe),
		.JTAGActive(JTAGActive),
    	.tck(tck)
	);
