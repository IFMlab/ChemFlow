from matplotlib import pyplot as plt
import pandas  as pd
import seaborn as sns
import numpy   as np

data = pd.read_csv('data.csv')

sns.barplot(data=data,x='Host-Guest',y='Delta',hue='Solvation')
plt.xticks(rotation=90)
plt.tight_layout()
plt.show()
