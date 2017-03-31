#!/usr/bin/python

from __future__ import division

import sys
import pandas as pd
import os, glob
import numpy as np

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
      r = round(mid.get_value('tradeValue') / mid.get_value('volume'), 1)

   return r

def comp_f(row, d, m, l):
   r = 0
   s = row.name
   e = s + m - 1

   if (s < l - m + 1):
      # close prices sum
      cSum = d.loc[s:e, :].sum().get_value('c')
      cAvg = round(cSum / m, 1)

      # delta ratio
      r = cAvg / d.get_value(s, 'vwap') - 1

   # print "delta: ", r
   return r

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   # move average
   ma  = 1

   # Specify datasets saved location/path
   os.chdir(srcDir)

   o_f() # enter "out" dir

   df = pd.read_json('data.json', encoding="UTF-8")

   sz = len(df['c'])
   # Add NEW dimension column of "volume weighted average price"
   df['vwap'] = df.apply(ma_f, args = (df, ma, sz,), axis=1)

   # Add NEW column of "delta"
   df['delta'] = df.apply(comp_f, args = (df, ma, sz,), axis=1)

   # column 'delta'
   last  = df.get_value(0, 'delta') * 100

   dfall_delta = df.loc[1:sz-ma+1, 'delta']
   stdev = dfall_delta.std(ddof=0) * 100
   mean  = dfall_delta.mean() * 100
   min   = dfall_delta.min()  * 100
   max   = dfall_delta.max()  * 100
   sigma = (last - mean) / stdev

   # last 250
   df250_delta = df.loc[1:251, 'delta']
   stdev2= df250_delta.std(ddof=0) * 100
   mean2 = df250_delta.mean() * 100
   min2  = df250_delta.min()  * 100
   max2  = df250_delta.max()  * 100
   sigma2= (last - mean2) / stdev2

   # Debug
   print df.head(100)
   print "..."
   print df.tail(100)

   print last, mean, stdev, sigma

   # For report
   f = open('item.json', 'a')
   print >> f, '"delta": %.2f, "mean": %.2f, "min": %.2f, "max": %.2f, "stdev": %.4f, "sigma": %.4f,' \
               % (last, mean, min, max, stdev, sigma)
   print >> f, '"mean250": %.2f, "min250": %.2f, "max250": %.2f, "stdev250": %.4f, "sigma250": %.4f'  \
               % (mean2, min2, max2, stdev2, sigma2)
   f.close()

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080
