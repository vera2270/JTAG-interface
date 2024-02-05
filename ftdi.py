import asyncio
import board
import digitalio
import pathlib
import time

clock_half_period = 0.000005 # [s] 10 ns = 0.010 ms = 0.000010 s
falling_edge = asyncio.Event()
rising_edge = asyncio.Event()
send = "1111101010110001" # 0xFAB1
end = "1111101010110000" # 0xFAB0


async def clock(delay: int, tck: digitalio.DigitalInOut):
	while True:
		tck.value = False
		falling_edge.set()
		await asyncio.sleep(delay)
		tck.value = True
		rising_edge.set()
		await asyncio.sleep(delay)

async def load_config(data: list, tms: digitalio.DigitalInOut, tdi: digitalio.DigitalInOut):
	# setup 
	await falling_edge.wait()
	tms.value = False
	await falling_edge.wait()
	tms.value = True
	await falling_edge.wait()
	tms.value = True
	await falling_edge.wait()
	tms.value = False
	await falling_edge.wait()
	tms.value = False
	await falling_edge.wait()
	# load instruction program
	tdi.value = True
	await falling_edge.wait()
	tdi.value = False
	await falling_edge.wait()
	tdi.value = True
	await falling_edge.wait()
	tdi.value = True
	# 
	tms.value = True
	await falling_edge.wait()
	tms.value = True
	await falling_edge.wait()
	tms.value = False
	await falling_edge.wait()
	tms.value = False
	for chunk in data[0]:
		binary = '{0:032b}'.format(chunk)
		for i in range(32):
			tdi.value = binary[i]
			if i > 15:
				tms.value = send[i-16]
			else:
				tms.value = False
			await falling_edge.wait()
	tdi.value = True
	for i in range(16):
		tms.value = end[i]
		await falling_edge.wait()
	tms.value = True


async def jtag():
	data = read_binary_file(pathlib.Path("sequential_16bit_en.bin"))

	tck = digitalio.DigitalInOut(board.D0)
	tck.direction = digitalio.Direction.OUTPUT
	tdi = digitalio.DigitalInOut(board.D1)
	tdi.direction = digitalio.Direction.OUTPUT
	tdo = digitalio.DigitalInOut(board.D2)
	tdo.direction = digitalio.Direction.INPUT
	tms = digitalio.DigitalInOut(board.D4)
	tms.direction = digitalio.Direction.OUTPUT

	tck_task = asyncio.create_task(clock(clock_half_period, tck))

	await load_config(data, tms, tdi)
	await asyncio.sleep(clock_half_period*10)
	tck_task.cancel()

def read_binary_file(filename: pathlib.Path) -> list:
	chunk_size = 4
	data = []
	with open(filename, "rb") as f:
		bits = f.read(chunk_size)
		while bits:
			data.append(bits) # read in chunks of chunk_size (=4) bytes
			bits = f.read(chunk_size)
	return data

def blinky():
	led = digitalio.DigitalInOut(board.C0)
	led.direction = digitalio.Direction.OUTPUT

	while True:
		led.value = True
		time.sleep(0.5)
		led.value = False
		time.sleep(0.5)

if __name__ == '__main__':
	asyncio.run(jtag())