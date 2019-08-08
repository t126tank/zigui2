#!/usr/bin/python3

from __future__ import division

import sys
import pandas as pd
import os, glob
import numpy as np
import json

# Classification [0] < bad < [1] < bdraw < [2] < gdraw < [3] < good < [4]
bdraw = -0.01  # bad  draw
gdraw =  0.01  # good draw
bad   = -0.0119
good  =  0.0121

def o_f():
   outpath = "out"
   if not os.path.exists(outpath):
      os.makedirs(outpath)

   os.chdir(outpath)

def ma_f(row, d, m, l):
   r = 0
   s = row.name
   e = s + m - 1
   # print "call: ", s

   if (s < l - m + 1):
      mid = d.loc[s:e, :].sum()
      r = round(mid.at['tradeValue'] / mid.at['volume'], 1)

   return r

def comp_f(row, d, p, q, o, dm, ma, l):
   r = -1
   s = row.name

   # iterate from last trade time
   if (s < q + o):
      pSum = d.loc[s:s+p-1, :].sum().at['mp']
      r = int(pSum / p)
      p1 = r
      p0 = int(p1*(1+bad))
      p2 = int(p1*(1+good))

      r = str(p0) + " " + str(p1) + " " + str(p2)

      # For report
      if s == 0:
         item = {}
         # Read in
         with open('item.json') as infile:
            item = json.load(infile)

         item['refPrice'] = p1
         item['price0'] = p0
         item['price1'] = p1
         item['price2'] = p2

         # Write out
         with open('item.json', 'w') as outfile:
            json.dump(item, outfile)

      return r

   if (s > l - dm - ma + 1):  # q < dim
      return int(r)

   # predict: p->q
   qSum = d.loc[s-q-o:s-1-o, :].sum().at['mp']
   qAvg = qSum / q

   # history
   pSum = d.loc[s:s+p-1, :].sum().at['mp']
   pAvg = pSum / p

   result = qAvg / pAvg - 1

   # print s,": ",pAvg, " -> ", qAvg

   '''
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

   # binary classification
   if (result > good):     # good
      r = 1
   else:
      r = 0
   '''

   if (result > good):     # good
      r = 2
   elif (result > bad):    # bad
      r = 1
   else:
      r = 0

   return int(r)


# apply: def csv_f(row, d, ma, q, o, dm, l):
def csv_f(d, ma, q, o, dm, l):
   csv = pd.DataFrame()
   s = q + o   # bias/offset
   e = l - ma - dm + 1

   for i in range(s, e+1):
      r = []
      for j in range(dm):
         idx = i + dm - j - 1
         r.append(d.at[idx, 'dim'])

      r.append(d.at[i, 'result'])
      csv = csv.append([r])

   # Reset idx
   csv = csv.reset_index(drop=True)

   # titles
   csv.columns.values[0] = e+1-s
   csv.columns.values[1] = dm

   csv.to_csv('data.csv', index=False)

def print_new_f(d, q, o, dm):
   for i in range(q+o):
      r = []
      for j in range(dm):
         idx = i + dm - j - 1
         r.append(round(d.at[idx, 'dim'], 1))

      # For NEW data predicting
      if i == 0:
         a = np.asarray([ r ]) # [ [1,2,3], [4,5,6], [7,8,9] ]
         np.savetxt("input.csv", a, delimiter=",", fmt='%10.2f')

      print(r,",")


def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   dim = 81
   ma  = 9
   p   = 2
   q   = 3
   offset = 1

   # Specify datasets saved location/path
   os.chdir(srcDir)

   o_f() # enter "out" dir

   df = pd.read_json('data.json', encoding="UTF-8")

   sz = len(df['mp'])
   # Add NEW dimension column of "dim"
   # dataLen = len(df['tradeTime'])
   # df['dim'] = np.random.randn(dataLen)
   # df['dim'] = df['mp'].map(lambda x: np.random.random())
   df['dim'] = df.apply(ma_f, args = (df, ma, sz,), axis=1)

   # Add NEW column of "classification"
   df['result'] = df.apply(comp_f, args = (df, p, q, offset, dim, ma, sz,), axis=1)

   print(df.head(40))
   print("...")
   print(df.tail(60))

   # from(q) - to(len - ma - [dim - 1])
   # Add NEW column of "classification"
   # df.apply(csv_f, args = (df, ma, q, offset, dim, sz,), axis=1)
   csv_f(df, ma, q, offset, dim, sz)

   # start(idx) = q
   # if p < dim then
   # end1 (idx) = len - ma - (dim - 1)
   # end2 (idx) = len - ma

   print_new_f(df, q, offset, dim)

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080
