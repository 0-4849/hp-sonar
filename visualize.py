import serial, math
import pyqtgraph as pg
from pyqtgraph.Qt import QtGui, QtCore

# in cm
spacing = 1.0
wavelength = 0.858
# angles in degrees
steering_angle = 20.0
phase_difference = 360.0 * spacing * math.sin(math.radians(steering_angle)) / wavelength
print(phase_difference, )

pg.setConfigOption('background', 'w')
pg.setConfigOption('foreground', 'k')

win = pg.GraphicsLayoutWidget(title="Signal from serial port") # creates a window
p = win.addPlot(title="Realtime plot")  # creates empty space for the plot in the window
p.setYRange(0, 255, padding=0)
curve = p.plot()
win.show()


with serial.Serial('/dev/ttyACM0', 12_000_000, timeout=0.02) as ser:
	while True:
		input("waiting (hit enter)")

		# convert the phase difference to bytes (big-endian) and send them
		# raspberry pi pico should return one measurement
		ser.write(int(65536 * phase_difference / 360.0).to_bytes(2, "big"))
		print(int(65536 * phase_difference / 360.0).to_bytes(2, "big"))
	
		while ser.in_waiting == 0 : continue

		b = ser.read(2**32)
		#if len(b) == 0: continue

		values = list(map(int, b))

		#print(list(map(chr, b[:30])))
		print(len(values))

		curve.setData(values)
		win.show()
		QtGui.QGuiApplication.processEvents()

