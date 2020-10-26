#!/usr/bin/env python

import sys
import numpy as np
import pandas as pd

if len(sys.argv) < 2:
  raise OSError("Usage: %s <AFNI's 3dmaskdump file> " % sys.argv[0])

input_file = str(sys.argv[1])

df = pd.read_csv(input_file, sep=' ', header=None, 
    names=['x', 'y', 'z', 'intensity'], 
    dtype={'x': np.float64, 'y': np.float64, 'z': np.float64, 'intensity': np.float64} )

# sort by intensity values 
df_sort = df.sort_values(by='intensity', ascending=False)

# return x y z coordinates with highest intensity value 
print ("%.5f %.5f %.5f" %(df_sort.iloc[0].x, df_sort.iloc[0].y, df_sort.iloc[0].z))
print ("%.5f %.5f %.5f" %(np.mean(df.x.values), np.mean(df.y.values), np.mean(df.z.values)))
print ("%.5f %.5f %.5f" %(np.mean(df.x.values*df.intensity.values), 
np.mean(df.y.values*df.intensity.values), np.mean(df.z.values*df.intensity.values))) 
