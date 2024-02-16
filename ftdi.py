import board
import digitalio
from enum import Enum
import pathlib
import time

clock_half_period = 0.0005 # [s] 10 ns = 0.010 ms = 0.000010 s
send = "1111101010110010" # 0xFAB2
end = "1111101010110011" # 0xFAB3

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

class JTAG:
	def __init__(self):
		self.tck = digitalio.DigitalInOut(board.D4)
		self.tck.direction = digitalio.Direction.OUTPUT
		self.tdi = digitalio.DigitalInOut(board.D5)
		self.tdi.direction = digitalio.Direction.OUTPUT
		self.tdo = digitalio.DigitalInOut(board.D6)
		self.tdo.direction = digitalio.Direction.INPUT
		self.tms = digitalio.DigitalInOut(board.D7)
		self.tms.direction = digitalio.Direction.OUTPUT
		self.tck.value = True
		self.tdi.value = True
		self.tms.value = True
		print("initialized JTAG port")
		print("1 sec timer starting now")
		self.clock_for(1)
		print("starting")
		
		self.controller = TapStateMachine()

	def next_state(self, tms_in: bool):
		self.tms.value = tms_in
		self.controller.next_state(tms_in)
		self.clock()

	def load_instruction(self, instruction: Instruction, end_selectDR: bool = False):
		self.clock()
		if self.controller.current_state.name == "TLRESET":
			self.next_state(False) # IDLE
		if self.controller.current_state.name == "IDLE":
			self.next_state(True) # SELECTDR
		assert self.controller.current_state.name == "SELECTDR"
		self.next_state(True) # SELECTIR
		self.next_state(False) # CAPTUREIR
		self.next_state(False) # SHIFTIR
		for bit in instruction.value:
			self.tdi.value = int(bit)
			print("tdi: ", self.tdi.value)
			self.clock()
		self.tdi.value = True
		self.next_state(True) # EXIT1IR
		self.next_state(True) # UPDATEIR
		if end_selectDR:
			self.next_state(True) # SELECTDR
		else:
			self.next_state(False) # IDLE
   
	def exec_instruction(self, data: list, end_selectDR: bool = False):
		if data == Instruction.IDCODE.name:
			data = [0 for _ in range(32)]
		self.clock()
		if self.controller.current_state.name == "IDLE":
			self.next_state(True) # SELECTDR
		assert self.controller.current_state.name == "SELECTDR"
		self.next_state(False) # CAPTUREDR
		self.next_state(False) # SHIFTDR
		for bit in data:
			self.tdi.value = int(bit)
			print("tdi: ", self.tdi.value)
			self.clock()
		self.tdi.value = True
		self.next_state(True) # EXIT1DR
		self.next_state(True) # UPDATEDR
		if end_selectDR:
			self.next_state(True) # SELECTDR
		else:
			self.next_state(False) # IDLE
   
	def load_and_exec(self, instruction: Instruction, data: list, end_selectDR: bool = False):
		self.load_instruction(instruction, end_selectDR)
		self.exec_instruction(data, end_selectDR)
  
	def reset(self):
		if self.controller.current_state.name == "IDLE":
			self.next_state(True) # SELECTDR
		if self.controller.current_state.name == "SELECTDR":
			self.next_state(True) # SELECTIR
		if self.controller.current_state.name == "SELECTIR":
			self.next_state(True) # TLRESET
		assert self.controller.current_state.name == "TLRESET"
		self.next_state(True) # TLRESET
  
	def load_config(self, data: list):
		self.load_instruction(Instruction.PROGRAM)
		# in run-test / idle state
		for chunk in data: 
			for byte in chunk:
				binary = '{0:08b}'.format(byte)
				for i in range(8):
					self.tdi.value = int(binary[i])
					self.clock()
			for i in range(16):
				self.tdi.value = int(send[i])
				self.clock()
    
		for i in range(16):
			self.tdi.value = int(end[i])
			self.clock()
		self.tdi.value = True
		# self.tms.value = True
	

	def clock_posedge(self):
		self.tck.value = True
		time.sleep(clock_half_period)

	def clock_negedge(self):
		self.tck.value = False
		time.sleep(clock_half_period)
		
	def clock(self):
		time.sleep(clock_half_period)
		self.tck.value = True
		print("tdo+: ", self.tdo.value)
		time.sleep(clock_half_period)
		self.tck.value = False
		print("tdo-: ", self.tdo.value)
		
	def clock_for(self, duration: int):
		start = time.time()
		stop = start + duration # duration in seconds
		while time.time() < stop:
			self.clock()


def read_binary_file(filename: pathlib.Path) -> list:
	chunk_size = 4
	data = []
	with open(filename, "rb") as f:
		bits = f.read(chunk_size)
		while bits:
			data.append(bits) # read in chunks of chunk_size (=4) bytes
			bits = f.read(chunk_size)
	return data

if __name__ == '__main__':
	jtag_i = JTAG()
	print("PRELOAD, 00111010")
	jtag_i.load_and_exec(Instruction.PRELOAD, "00111010")
	print("EXTEST, 00000000")
	jtag_i.load_and_exec(Instruction.EXTEST, "00000000")
	print("IDCODE")
	jtag_i.load_and_exec(Instruction.IDCODE, Instruction.IDCODE.name)
	print("INTEST, 11000101")
	jtag_i.load_and_exec(Instruction.INTEST, "11000101")
	print("BYPASS, 00111010")
	jtag_i.load_and_exec(Instruction.BYPASS, "00111010")

	# data_bin = read_binary_file(pathlib.Path("sequential_16bit_en.bin"))
	# jtag_i.load_config(data_bin)
	print("1 sec timer starting now")
	jtag_i.clock_for(1)
	print("timer ended")