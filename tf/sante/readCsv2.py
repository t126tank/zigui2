#!/usr/bin/python

import sys
import pandas as pd
import os, glob

from itertools import groupby 
from collections import OrderedDict
import json

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   frame = pd.DataFrame()
   list_ = []

   # Specify datasets saved location/path
   os.chdir(srcDir)

   # Fetch all *.csv files
   for csvFile in glob.glob("*.csv"):
      # print csvFile

      # Specify encode and read csv contents "SHIFT-JIS"
      df= pd.read_csv(csvFile, encoding="SHIFT-JIS")
      # print df

      df = df[df.columns[:7]]
      df.dropna(how='all')

      # df=df.rename(columns = {'two':'new_name'})
      df.columns.values[0] = "dateTime"
      df.columns.values[1] = "o"
      df.columns.values[2] = "h"
      df.columns.values[3] = "l"
      df.columns.values[4] = "c"
      df.columns.values[5] = "volume"
      df.columns.values[6] = "tradeValue"

      list_.append(df)

   # Concat
   frame = pd.concat(list_)

   # Convert all data
   frame.to_json('data.json', orient='records')

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py
