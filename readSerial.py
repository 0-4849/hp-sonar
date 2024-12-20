import serial
import functools
from scipy import fft
from matplotlib import pyplot as plt

with serial.Serial('/dev/ttyUSB0', 115200, timeout=0.5) as ser:
    while True:
        b = ser.read(1000)

        values = list(map(int, b))
        norm_values = list(map(lambda x: abs(x - 128), values))

        #print(sum(norm_values) / len(values))
        #print("\033[2J")
        print(values)
        print(4*functools.reduce(max, norm_values, 0))

#        plt.clf()
#        plt.ylim(0, 255)
#        plt.plot(values)
#        plt.pause(0.05)
#
#    plt.show()

