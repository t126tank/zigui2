#!/usr/bin/python

import sys
import pandas as pd
import os, glob
import numpy as np

def ma(row):
   return row['tradeValue'] / row['volume']

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   dim = 8
   ma0 = 4
   p   = 3
   q   = 5

   # Classification [-2] < bad < [-1] < bdraw < [0] < gdraw < [1] < good < [2]
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
   df['dim'] = df.apply(ma, axis=1)

   print df.tail(10)

   # start(idx) = q
   # if p < dim then
   # end1 (idx) = len - ma0 - (dim - 1)
   # end2 (idx) = len - ma0

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080
