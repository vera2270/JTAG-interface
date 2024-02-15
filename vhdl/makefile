
SIM = ghdl
TOPLEVEL_LANG = vhdl
VHDL_SOURCES = *.vhd
TOPLEVEL = tap
export MODULE = test_jtag
COMPILE_ARGS += --std=08


# run make
all: analyse coco_run

analyse:
	ghdl -m --std=08 --workdir=sim_build tap

# run 
run:
	ghdl -r --std=08 --workdir=sim_build jtag_tb --wave=wave.ghw --stop-time=1900ns

# clean
clean:
	ghdl --clean --workdir=sim_build

# import sources
import:
	ghdl -i -fexplicit --ieee=synopsys --std=08 --workdir=sim_build *.vhd

coco_run:
	ghdl -r --std=08 --workdir=sim_build tap --wave=wave.ghw --vpi=/home/vera/pyvenv/lib/python3.11/site-packages/cocotb/libs/libcocotbvpi_ghdl.so
#	include $(shell cocotb-config --makefiles)/Makefile.sim
