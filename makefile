
all: compile run

compile:
	iverilog -s jtag_tb -o jtag_tb.vvp *.v

run:
	vvp jtag_tb.vvp