# Sample Python — runs on the bundled Pyodide runtime (no network needed).
# Switch the kernel to Python, then press Run. Text goes to Console, the plot to Plots.

import numpy as np
import matplotlib.pyplot as plt

x = np.random.randn(200)
print("n:", x.size, " mean:", round(float(x.mean()), 3), " sd:", round(float(x.std()), 3))

plt.hist(x, bins=20, color="#28A745", edgecolor="white")
plt.title("200 draws from N(0, 1)")
plt.xlabel("value")
plt.show()
