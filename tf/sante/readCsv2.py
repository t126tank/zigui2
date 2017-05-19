#!/usr/bin/python

import sys
import pandas as pd
import os, glob

def o_f():
   outpath = "out"
   if not os.path.exists(outpath):
      os.makedirs(outpath)

   os.chdir(outpath)

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
      df.columns.values[0] = "tradeTime"
      df.columns.values[1] = "o"
      df.columns.values[2] = "h"
      df.columns.values[3] = "l"
      df.columns.values[4] = "c"
      df.columns.values[5] = "volume"
      df.columns.values[6] = "tradeValue"

      list_.append(df)

   # Concat
   frame = pd.concat(list_)

   # Remove odd rows
   frame = frame[frame.volume > 0] # [frame.volume != 0]

   col_name = frame.columns[0]
   # print "[0]: ", col_name
   # print "Dir: ", srcDir
   # frame = frame.rename(columns = {col_name: 'tradeTime'})
   # print frame.tradeTime

   # Drop duplicated
   frame.drop_duplicates(subset=[col_name], inplace=True)

   # Sort
   frame[col_name] = pd.to_datetime(frame.tradeTime)
   # frame.sort('tradeTime') This now sorts in date order (deprecated)
   frame.sort_values(by=[col_name], ascending=[False], inplace=True) # from ver 0.17
   frame[col_name] = frame[col_name].dt.strftime('%Y-%m-%d')

   # Reset idx : severl files have index 0
   frame = frame.reset_index(drop=True)

   # Output datasets
   o_f()

   # Convert all data
   frame.to_json('data.json', orient='records')
   frame.to_csv('history.csv', index=False)

   # For report
   ldate = frame.get_value(0, 'tradeTime')
   f = open('item.json', 'a')
   print >> f, '"code": "%s", "fromDate": "%s",' % (srcDir[7:11], ldate)
   f.close()


if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080
