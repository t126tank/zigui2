#!/usr/bin/python3

import sys
import pandas as pd
import json

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   result = []

   item = {}
   with open(srcDir + '/out/item.json') as infile:
      item = json.load(infile)

   itemArr = []
   # array/list has ONLY ONE element
   itemArr.append(item)

   # pandas loads array/list
   itemDf = pd.DataFrame(itemArr)
   # item = pd.read_json(srcDir + '/out/item.json')
   result.append(itemDf)

   nn = pd.read_json('nn.json')
   result.append(nn)

   # print(result)
   frame = pd.concat(result)
   frame = frame.reset_index(drop=True)

   frame.to_json('nn.json', orient='records')
   frame.to_csv('nn.csv', index=False)

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://stackoverflow.com/questions/23520542/issue-with-merging-multiple-json-files-in-python

