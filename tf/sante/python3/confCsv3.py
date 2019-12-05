#!/usr/bin/python3

import json

def loadConf(path):
   conf = {}

   # Relative Path
   with open(path) as infile:
      conf = json.load(infile)

   return conf
