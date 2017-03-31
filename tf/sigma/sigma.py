#!/usr/bin/python

import sys
import pandas as pd

def main(argv):
   srcDir = "."
   if len(argv) != 0:
      srcDir = argv[0]

   result = []

   item = pd.read_json(srcDir + '/out/item.json')
   result.append(item)

   sigma  = pd.read_json('sigma.json')
   result.append(sigma)

   frame = pd.concat(result)
   frame = frame.reset_index(drop=True)

   frame.to_json('sigma.json', orient='records')
   frame.to_csv('sigma.csv', index=False)

if __name__ == "__main__":
   main(sys.argv[1:])

# Ref:
## http://stackoverflow.com/questions/23520542/issue-with-merging-multiple-json-files-in-python

