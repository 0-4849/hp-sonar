from math import sin,cos,pi,sqrt
from cmath import exp
from matplotlib import pyplot as plt
 
frequency = 40e3 # [Hz]
wavelength = 343/frequency # [m]
spacing = 0.01 # [m]
nr_of_Tx = 8
d_obs = 1.715 # observation distance [m]
obs_steps = 1000 # number of angles for the plot
 
angles = [-pi/4+0.5*n*pi/obs_steps for n in range(obs_steps)]
Tx_coords = [-spacing*((nr_of_Tx-1)/2) + spacing*n for n in range(nr_of_Tx)]
obs_coords = [(d_obs*sin(angle),d_obs*cos(angle)) for angle in angles]
 
powers = []
 
for (x,y) in obs_coords:
    power = 0 + 0j
    for TX_x in Tx_coords:
        power += exp(2j * pi * sqrt((x-TX_x)**2+y**2) / wavelength)
    powers.append(abs(power))
 
plt.figure()
plt.plot(powers)
plt.show()
 
