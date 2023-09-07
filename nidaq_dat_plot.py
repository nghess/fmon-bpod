import numpy as np
import matplotlib.pyplot as plt
import time

# Import .dat and zip raw and smoothed into DF
data = np.fromfile('D:/NiDAQ_sniff.dat', dtype=float)

print(data.shape)

#plt.plot(data[0:800:4])
plt.plot(data[1:int(3200/80):4])
#plt.plot(data[2::4])
#plt.plot(data[3::4])
plt.show()
