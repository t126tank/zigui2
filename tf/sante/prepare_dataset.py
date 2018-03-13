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
   valsz = int(round(sz * 0.2))
   tstsz = int(round(sz * 0.1))

   # rebuild path+filename as "./png/xxxx.png"
   # df = df["name"].map(lambda x: './png/'+x)
   df['name'] = './png/' + df['name']

   # value datasets
   rows = rd.sample(df.index, valsz)
   df_20 = df.ix[rows]
   df_20.to_json('value.json', orient='records')

   df_80 = df.drop(rows)

   # test datasets
   rows = rd.sample(df_80.index, tstsz)
   df_10 = df_80.ix[rows]
   df_10.to_json('test.json', orient='records')

   # training datasets
   df_70 = df_80.drop(rows)
   df_70.to_json('training.json', orient='records')
   print 'training: %d, value: %d, test: %d, total: %d' % (len(df_70.index), valsz, tstsz, sz)

   # For report deprecated
   '''
   f = open('item.json', 'a')
   print >> f, '"training": %d, "value": %d,' % (trnsz, valsz)
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