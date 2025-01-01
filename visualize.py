import serial, math, time
import numpy as np
import pyqtgraph as pg
from pyqtgraph.Qt import QtGui, QtCore

# in cm
spacing = 1.0
wavelength = 0.858

start_angle = -30
end_angle = 30
angle_step = 1

# uncomment for light mode
#pg.setConfigOption('background', 'w')
#pg.setConfigOption('foreground', 'k')

win = pg.GraphicsLayoutWidget(title="SONAR") 

signal_plot = win.addPlot(title="Signal")  
signal_plot.setYRange(0, 255, padding=0)

img_width = 512
img_height = 512
img_plot = win.addPlot(title="Scan2")
img_data = np.zeros((img_height, img_width), dtype=int)
img_item = pg.ImageItem(image=img_data, levels=(0,128))
img_plot.addItem(img_item)

signal = signal_plot.plot()
img_plot.plot()

win.show()


with serial.Serial('/dev/ttyACM0', 12_000_000, timeout=0.02) as ser:
	while True:
		for angle in range(start_angle, end_angle, angle_step):
			phase_difference = 360.0 * spacing * math.sin(math.radians(angle)) / wavelength
			phase_difference %= 360.0

			# convert the phase difference to bytes (big-endian) and send them
			# raspberry pi pico should return one measurement
			ser.write(int(65536 * phase_difference / 360.0).to_bytes(2, "big"))
	
			while ser.in_waiting == 0 : continue

			b = ser.read(2**32)

			values = list(map(int, b))
			norm_values = [abs(x-128) for x in values]
			print(f"received {len(values)} datapoints")

			maxima = []
			
			for i in range(1, len(norm_values) - 1):
				if norm_values[i - 1] <= norm_values[i] >= norm_values[i + 1]:
					maxima.append((i, norm_values[i]))
				

			for (i, val) in maxima:
				# x = img_width // 2 + int(img_width * i / (2 * len(values)) * math.sin(math.radians(angle)))
				# y = int(img_width * math.cos(math.radians(angle)) * i / len(values))

				stroke_res = 10
				for theta in [i / stroke_res for i in range(int(stroke_res * (angle - angle_step / 2)), int(stroke_res * (angle + angle_step / 2)))]:
					x = img_width // 2 + int(img_width * i / (2 * len(values)) * math.sin(math.radians(theta)))
					y = int(img_width * math.cos(math.radians(theta)) * i / len(values))
					img_data[y,x] = val


			img_item.setImage(img_data)
			signal.setData(values)

			QtGui.QGuiApplication.processEvents()

