#!/usr/bin/python

import sys
import pandas as pd
import os, glob
import numpy as np

def ma_f(row, ma, len, dim):
   rnt = 0
   start = row.name
   end = start + ma

   if (end < len - ma - (dim - 1)):
      rnt = row.loc[start:end, ['tradeValue']].sum() / row.loc[start:end, ['volume']].sum()

   return rnt

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   dim = 8
   ma  = 4
   p   = 3
   q   = 5

   # Classification [0] < bad < [1] < bdraw < [2] < gdraw < [3] < good < [4]
   bdraw = -0.01  # bad  draw
   gdraw =  0.01  # good draw
   bad   = -0.03
   good  =  0.03

   # Specify datasets saved location/path
   os.chdir(srcDir)

   df = pd.read_json('data.json', encoding="UTF-8")

   # Add NEW dimension column of "dim"
   # dataLen = len(df['tradeTime'])
   # df['dim'] = np.random.randn(dataLen)
   # df['dim'] = df['c'].map(lambda x: np.random.random())
   df['dim'] = df.apply(ma_f, args = (ma, len, dim, ), axis=1)

   print df.head(10)
   print "..."
   print df.tail(10)

   # start(idx) = q
   # if p < dim then
   # end1 (idx) = len - ma - (dim - 1)
   # end2 (idx) = len - ma

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080
