import serial, math, time, threading
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

last_measurement = np.zeros(200, dtype=int)

win = pg.GraphicsLayoutWidget(title="SONAR") 

signal_plot = win.addPlot(title="signal", row=0, col=0)  
signal_plot.setYRange(0, 255, padding=0)

maxima_per_buffer_plot = win.addPlot(title="maxima of signal per buffer (24)", row=2, col=0)
maxima_per_buffer_plot.setYRange(0, 128, padding=0)

img_width = 400
img_height = 400
img_plot = win.addPlot(title="scan", col=1, row=0, rowspan=3)
img_plot.setAspectLocked(img_height / img_width)
img_data = np.zeros((img_width, img_height), dtype=int)
img_item = pg.ImageItem(image=img_data, levels=(0,128))
img_plot.addItem(img_item)

signal = signal_plot.plot()
maxima_per_buffer = maxima_per_buffer_plot.plot()
img_plot.plot()

win.show()

def render(measurement, angle):
	global img_data

	norm_values = np.abs(measurement - 128)
	maximum_per_buffer_values = np.max(np.array(norm_values.reshape((-1, 24))), axis=1)
	rect_height = math.floor(img_height / len(maximum_per_buffer_values)) + 1

	for (i, val) in enumerate(maximum_per_buffer_values):
		normalized_distance = i / len(maximum_per_buffer_values)
		
		rect_width = math.ceil(
			(angle_step / (end_angle - start_angle)) 
			* (math.pi * img_height * (end_angle - start_angle) / 180) 
			* normalized_distance
		)

		halved, remainder = divmod(rect_width, 2)

		x = img_width // 2 + int(img_height * normalized_distance * math.sin(math.radians(angle)))
		y = int(img_height * normalized_distance * math.cos(math.radians(angle)))

		# note that we swap the x and y indices to make the scan appear vertical instead of horizontal
		img_data[x : x + rect_width, y : y + rect_height] = val

	inverted = 128 - img_data
	img_item.setImage(inverted)
	maxima_per_buffer.setData(last_measurement)
	signal.setData(measurement)
	QtGui.QGuiApplication.processEvents()



def get_measurement(angle):
	global last_measurement

	phase_difference = 360.0 * spacing * math.sin(math.radians(angle)) / wavelength
	phase_difference %= 360.0

	# convert the phase difference to bytes (big-endian) and send them
	# raspberry pi pico should return one measurement
	ser.write(int(65536 * phase_difference / 360.0).to_bytes(2, "big"))

	while ser.in_waiting == 0 : continue

	b = ser.read(2**32)

	values = np.frombuffer(b, dtype=np.uint8).astype(int)
	last_measurement = values


	
with serial.Serial('/dev/ttyACM0', 12_000_000, timeout=0.02) as ser:
	while True:
		t0 = time.time()
		get_measurement(start_angle)
		for angle in range(start_angle, end_angle, angle_step):
			measure_t = threading.Thread(target=get_measurement, args=(angle,))
			render_t = threading.Thread(target=render, args=(last_measurement, angle))

			measure_t.start()
			render_t.start()

			measure_t.join()
			render_t.join()


		print(f"took {time.time()-t0} for one entire frame")

