import serial
import pyqtgraph as pg
from pyqtgraph.Qt import QtGui, QtCore

pg.setConfigOption('background', 'w')
pg.setConfigOption('foreground', 'k')

win = pg.GraphicsLayoutWidget(title="Signal from serial port") # creates a window
p = win.addPlot(title="Realtime plot")  # creates empty space for the plot in the window
p.setYRange(0, 255, padding=0)
curve = p.plot()
win.show()

with serial.Serial('/dev/ttyACM0', 12_000_000, timeout=0.02) as ser:
    while True:
        while ser.in_waiting == 0 : continue

        b = ser.read(2**32)
        #if len(b) == 0: continue

        values = list(map(int, b))

        print(len(values))

        curve.setData(values)
        win.show()
        QtGui.QGuiApplication.processEvents()

