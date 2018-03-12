#!/usr/bin/python

from __future__ import division

import sys
import pandas as pd
import os, glob
import random as rd

def o_f():
   outpath = "png"
   if not os.path.exists(outpath):
      os.makedirs(outpath)

   os.chdir(outpath)

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   # Specify datasets saved location/path
   os.chdir(srcDir)

   # o_f()

   df = pd.read_json('commit.json', orient='records')

   sz = len(df.index)
   tstsz = int(round(sz * 0.2))

   # rebuild path+filename as "./png/xxxx.png"
   df = df["name"].map(lambda x: './png/'+x)

   rows = rd.sample(df.index, tstsz)
   df_20 = df.ix[rows]
   df_20.to_json('test.json', orient='records')

   df_80 = df.drop(rows)
   df_80.to_json('training.json', orient='records')
   print 'training: %d, test: %d, total: %d,' % (len(df_80.index), len(df_20.index), len(df.index))

   # For report deprecated
   '''
   f = open('item.json', 'a')
   print >> f, '"training": %d, "test": %d,' % (trnsz, tstsz)
   f.close()
   '''

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080