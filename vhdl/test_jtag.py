
from enum import Enum
import pathlib

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

clock_period = 10

class Instruction(Enum):
	BYPASS = "000"
	IDCODE = "001"
	SAMPLE = "010"
	PRELOAD = "010"
	EXTEST = "100"
	INTEST = "110"
	PROGRAM = "101"

class State(Enum):
	TLRESET = "F"
	IDLE = "C"
	SELECTDR = "7"
	CAPTUREDR = "6"
	SHIFTDR = "2"
	EXIT1DR = "1"
	PAUSEDR = "3"
	EXIT2DR = "0"
	UPDATEDR = "5"
	SELECTIR = "4"
	CAPTUREIR = "E"
	SHIFTIR = "A"
	EXIT1IR = "9"
	PAUSEIR = "8"
	EXIT2IR = "B"
	UPDATEIR = "D"


# define tap controller state machine
class TapStateMachine:	
	def __init__(self, state=State.TLRESET):
		self.current_state = state

	def set_state(self, state: State):
		self.current_state = state

	def next_state(self, tms_in: int):
		match self.current_state.name:
			case "TLRESET":
				if tms_in == 0:
					self.current_state = State.IDLE
			case "IDLE":
				if tms_in == 1:
					self.current_state = State.SELECTDR
			case "SELECTDR":
				if tms_in == 0:
					self.current_state = State.SELECTIR
				elif tms_in == 1:
					self.current_state = State.CAPTUREDR
			case "CAPTUREDR":
				if tms_in == 0:
					self.current_state = State.SHIFTDR
				elif tms_in == 1:
					self.current_state = State.EXIT1DR
			case "SHIFTDR":
				if tms_in == 1:
					self.current_state = State.EXIT1DR
			case "EXIT1DR":
				if tms_in == 0:
					self.current_state = State.PAUSEDR
				elif tms_in == 1:
					self.current_state = State.UPDATEDR
			case "PAUSEDR":
				if  tms_in == 1:
					self.current_state = State.EXIT2DR
			case "EXIT2DR":
				if tms_in == 0:
					self.current_state = State.SHIFTDR
				elif tms_in == 1:
					self.current_state = State.UPDATEDR
			case "UPDATEDR":
				if tms_in == 0:
					self.current_state = State.IDLE
				elif tms_in == 1:
					self.current_state = State.SELECTDR
			case "SELECTIR":
				if tms_in == 0:
					self.current_state = State.CAPTUREIR
				elif tms_in == 1:
					self.current_state = State.TLRESET
			case "CAPTUREIR":
				if tms_in == 0:
					self.current_state = State.SHIFTIR
				elif tms_in == 1:
					self.current_state = State.EXIT1IR
			case "SHIFTIR":
				if tms_in == 1:
					self.current_state = State.EXIT1IR
			case "EXIT1IR":
				if tms_in == 0:
					self.current_state = State.PAUSEIR
				elif tms_in == 1:
					self.current_state = State.UPDATEIR
			case "PAUSEIR":
				if tms_in == 1:
					self.current_state = State.EXIT2IR
			case "EXIT2IR":
				if tms_in == 0:
					self.current_state = State.SHIFTIR
				elif tms_in == 1:
					self.current_state = State.UPDATEIR
			case "UPDATEIR":
				if tms_in == 0:
					self.current_state = State.IDLE
				elif tms_in == 1:
					self.current_state = State.SELECTDR

async def load_instruction(dut, controller: TapStateMachine, instruction: Instruction, end_selectDR = False):
	await FallingEdge(dut.tck)
	if controller.current_state.name == "TLRESET":
		dut.tms.value = 0
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# IDLE
	if controller.current_state.name == "IDLE":
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# SELECTDR
	assert controller.current_state.name == "SELECTDR"
	dut.tms.value = 1
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# SELECTIR
	dut.tms.value = 0
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# CAPTUREIR
	dut.tms.value = 0
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# SHIFTIR
	for bit in instruction.value:
		dut.tdi.value = int(bit)
		await Timer(clock_period, units="ns")
	dut.tdi.value = 1 # when not driven tdi
	dut.tms.value = 1
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# EXIT1IR
	dut.tms.value = 1
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# UPDATEIR
	if end_selectDR:
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# SELECTDR
	else:
		dut.tms.value = 0
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# IDLE

async def exec_instruction(dut, controller: TapStateMachine, data: str, end_selectDR = False):
	if data == Instruction.IDCODE.name:
		data = [0 for _ in range(32)]
	await FallingEdge(dut.tck)
	if controller.current_state.name == "IDLE":
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# SELECTDR
	assert controller.current_state.name == "SELECTDR"
	dut.tms.value = 0
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# CAPTUREDR
	dut.tms.value = 0
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# SHIFTDR
	for bit in data:
		dut.tdi.value = int(bit)
		await Timer(clock_period, units="ns")
	dut.tdi.value = 1 # when not driven tdi
	dut.tms.value = 1
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# EXIT1DR
	dut.tms.value = 1
	await Timer(clock_period, units="ns")
	controller.next_state(dut.tms.value)
	# UPDATEDR
	if end_selectDR:
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# SELECTDR
	else:
		dut.tms.value = 0
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# IDLE

async def load_and_exec(dut, controller: TapStateMachine, instruction: Instruction, data: str, end_selectDR = False):
	await load_instruction(dut, controller, instruction, end_selectDR)
	await Timer(clock_period, units="ns")
	await exec_instruction(dut, controller, data, end_selectDR)
	await Timer(clock_period, units="ns")

async def reset(dut, controller: TapStateMachine):
	await FallingEdge(dut.tck)
	if controller.current_state.name == "IDLE":
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# SELECTDR
	if controller.current_state.name == "SELECTDR":
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# SELECTIR
	if controller.current_state.name == "SELECTIR":
		dut.tms.value = 1
		await Timer(clock_period, units="ns")
		controller.next_state(dut.tms.value)
		# TLRESET
	assert controller.current_state.name == "TLRESET"
	dut.tdi.value = 1


async def load_config(dut, controller: TapStateMachine, config: list):
	await load_instruction(dut, controller, Instruction.PROGRAM)

	send = "1111101010110010" # 0xFAB2
	end = "1111101010110011" # 0xFAB3

	for chunk in config:
		for i in range(32):
			dut.tdi.value = int(chunk[i])
			await Timer(clock_period, units="ns")
		for i in range(16):
			dut.tdi.value = int(send[i])
			await Timer(clock_period, units="ns")
		
	# exit config
	for i in range(16):
		dut.tdi.value = int(end[i])
		await Timer(clock_period, units="ns")
	
	dut.tdi.value = 1

def read_file(filename: pathlib.Path) -> list:
	with open(filename, "r") as f:
		data = f.readlines()
	return data

@cocotb.test()
async def test(dut):
	cocotb.start_soon(Clock(dut.tck, clock_period, units="ns").start())
	dut.pins_in.value = 0b0100
	dut.logic_pins_out.value = 0b0101
	dut.tdi.value = 1 # pull up when not driven
	dut.tms.value = 1 # pull up when not driven
	controller = TapStateMachine()

	await Timer(25, units="ns")
	await FallingEdge(dut.tck)

	await load_and_exec(dut, controller, Instruction.PRELOAD, "00111010")
	assert dut.bsr_in.data.value == 0b10100 or 0b10101, "bsr_in.data is wrong"
	assert dut.bsr_out.data.value == 0b00110 or 0b00111, "bsr_in.data is wrong"
	await load_and_exec(dut, controller, Instruction.EXTEST, "00000000")

	await load_and_exec(dut, controller, Instruction.IDCODE, Instruction.IDCODE.name)
	await load_and_exec(dut, controller, Instruction.INTEST, "11000101")

	data = read_file("test.txt")
	await load_config(dut, controller, data)

	await load_and_exec(dut, controller, Instruction.BYPASS, "00111010")

	await Timer(25, units="ns")
