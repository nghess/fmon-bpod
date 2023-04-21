import numpy as np
import matplotlib.pyplot as plt
import time

# Import .dat and zip raw and smoothed into DF
data = np.fromfile('D:/NiDAQ3.dat', dtype=float)

print(data.shape)

plt.plot(data[0:-1:4])
plt.plot(data[1:-1:4])
plt.plot(data[2:-1:4])
plt.plot(data[3:-1:4])
plt.show()
