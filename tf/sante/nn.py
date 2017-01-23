#!/usr/bin/python

import sys
import pandas as pd

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   nn  = pd.read_json('nn.json')
   tmp = pd.read_json(srcDir + '/out/item.json')

   concat = pd.concat([nn, tmp], ignore_index=True, axis=1)
   concat.to_json('nn.json', orient='records')

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://pandas.pydata.org/pandas-docs/stable/genindex.html
## http://stackoverflow.com/questions/33642673/convert-csv-to-json-in-specific-format-using-python
## http://www.nephridium-labs.com/blog/converting-between-json-and-csv-using-pandas/
## https://github.com/nephridium/csv2json/blob/master/csv2json.py

# $ pip install -U pandas --upgrade --proxy=http://id:pw@proxy.global.net:8080
