#!/usr/bin/python

from __future__ import division

import sys
import pandas as pd
import os, glob
import numpy as np

# Classification [0] < bad < [1] < bdraw < [2] < gdraw < [3] < good < [4]
bdraw = -0.01  # bad  draw
gdraw =  0.01  # good draw
bad   = -0.04
good  =  0.04

def ma_f(row, d, m, l):
   r = 0
   s = row.name
   e = s + m - 1
   # print "call: ", s

   if (s < l - m + 1):
      mid = d.loc[s:e, :].sum()
      r = mid.get_value('tradeValue') / mid.get_value('volume')

   return r

def comp_f(row, d, p, q, dm, l):
   r = -1
   s = row.name

   if ((s < q) or (s > l - dm - p)):  # q < dim
      return r

   # predict: p->q
   qSum = d.loc[s-q:s-1, :].sum().get_value('c')
   qAvg = qSum / q

   # history
   pSum = d.loc[s:s+p-1, :].sum().get_value('c')
   pAvg = pSum / p

   result = qAvg / pAvg - 1

   # print s,": ",pAvg, " -> ", qAvg

   if (result > good):
      r = 4
   elif (result > gdraw):
      r = 3
   elif (result > bdraw):
      r = 2
   elif (result > bad):
      r = 1
   else:
      r = 0

   return r


def csv_f(row, d, ma, q, dm, l):
   csv = pd.DataFrame()
   s = q
   e = l - ma - dm + 1

   for i in range(s, e+1):
      r = []
      for j in range(dm):
         idx = i + dm - j - 1
         r.append(d.get_value(idx, 'dim'))

      r.append(d.get_value(i, 'result'))
      csv = csv.append([r])

   # Reset idx
   csv = csv.reset_index(drop=True)

   # titles
   csv.columns.values[0] = e+1-s
   csv.columns.values[1] = dm

   csv.to_csv('data.csv', index=False)

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   dim = 9
   ma  = 5
   p   = 4
   q   = 6

   # Specify datasets saved location/path
   os.chdir(srcDir)

   df = pd.read_json('data.json', encoding="UTF-8")

   sz = len(df['c'])
   # Add NEW dimension column of "dim"
   # dataLen = len(df['tradeTime'])
   # df['dim'] = np.random.randn(dataLen)
   # df['dim'] = df['c'].map(lambda x: np.random.random())
   df['dim'] = df.apply(ma_f, args = (df, ma, sz,), axis=1)

   # Add NEW column of "classification"
   df['result'] = df.apply(comp_f, args = (df, p, q, dim, sz,), axis=1)

   print df.head(20)
   print "..."
   print df.tail(20)

   # from(q) - to(len - ma - [dim - 1])
   # Add NEW column of "classification"
   df.apply(csv_f, args = (df, ma, q, dim, sz,), axis=1)

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
