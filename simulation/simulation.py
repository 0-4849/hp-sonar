from math import sin,cos,pi,sqrt
from matplotlib import pyplot as plt
import random

spacing_randomness = 0.002 # +-1 mm of randomness in the spacing between elements
power_randomness = 0.6 # +-30% of randomness in transducer output power 
phase_randomness = pi / 2 # +-pi/4 of randomness in phase shift

spacing_randomness = 0
power_randomness = 0
#phase_randomness = 0

frequency = 40e3
wavelength = 343/frequency
spacing = 0.01
nr_of_Tx = 9 # only odd for now
d_obs = 1 # observation distance
obs_steps = 1000 # number of angles for the plot

# random.seed(60)

Tx_coords = [-spacing*((nr_of_Tx-1)/2)+(random.random() - 0.5)*spacing_randomness + spacing*n for n in range(nr_of_Tx)]
obs_coords = [(d_obs*sin(-pi/2+n*pi/obs_steps),d_obs*cos(-pi/2 + n*pi/obs_steps)) for n in range(obs_steps)]

phase_shifts = [(random.random() - 0.5) * phase_randomness  for _ in range(nr_of_Tx)]

powers = []

for (x,y) in obs_coords:
    power = 0
    for i, TX_x in enumerate(Tx_coords):
        power   += sin(2 * pi * sqrt((x-TX_x)**2+y**2) / wavelength  
                + phase_shifts[i]) * (1 + power_randomness * (random.random() - 0.5)) 

    powers.append(abs(power))

print(phase_shifts)
 
plt.figure()
plt.plot(powers)
plt.show()
