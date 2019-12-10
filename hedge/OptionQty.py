#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import codecs
import csv
import datetime
import io
import json
import numpy as np
import os
import re
import requests
import shutil
import urllib3
from urllib3.exceptions import InsecureRequestWarning
urllib3.disable_warnings(InsecureRequestWarning)
import sys
from bs4 import BeautifulSoup


FUTURE = "FUT"
OPT_PUT  = "PUT"
OPT_CALL = "CALL"


class Trader:
   def __init__(self, cd, ja, en):
      self.cd = cd
      self.ja = ja
      self.en = en

   def getCd(self):
      return self.cd

   def getJa(self):
      return self.ja

   def getEn(self):
      return self.en


class Target:
   def __init__(self, jpxCd, instrument, qty):
      self.jpxCd = jpxCd
      self.instrument = instrument
      self.qty = qty

   def getJpxCd(self):
      return self.jpxCd

   def getInstrument(self):
      return self.instrument

   def getQty(self):
      return self.qty


class Instrument:
   def __init__(self, type, target, end, kp):
      self.type   = type
      self.target = target
      self.end    = end
      self.kp     = kp

   def getType(self):
      return self.type

   def getTarget(self):
      return self.target

   def getEnd(self):
      return self.end

   def getKp(self):
      return self.kp


def default_method(item):
    if isinstance(item, object) and hasattr(item, '__dict__'):
        return item.__dict__
    else:
        raise TypeError


class TargetEncoder(json.JSONEncoder):
   def default(self, obj):
      if isinstance(obj, Target) and hasattr(obj, '__dict__'):
         return obj.__dict__
      return super(TargetEncoder, self).default(obj) # 他の型はdefaultのエンコード方式を使用


def createInstrument(row):
   kp = 0
   items = row.split(',')[1].split('_')

   if items[0].strip().upper() != FUTURE:
      kp = int(items[3])

   return Instrument(items[0], items[1], int(items[2]), kp)


def main(argv):
   # load traders' info
   traders = []

   # Relative Path, depends on OS utf-8 -> sjis
   with open('traders.json', encoding='utf-8') as f:
      traders = json.load(f)

   # read csv line-by-line (BOM of UTF-8)
   with io.open('20191206_volume_by_participant_whole_day.csv', 'rt', encoding='utf_8_sig') as f:
      # one target starts
      data  = {}
      start = False
      num   = 0

      # data part
      date = 0
      info = []

      target = {}
      jpxCd = ''
      instrument = {}
      qty = []

      for row in f:
         r = row.strip()

         # data["date"]
         if 'Trade Date' in r:
            date = int([d for d in r.split(',') if '20' in d][0].strip())
            # print(date)
            continue

         if r == '' or '-,-,' in r:
            if start:
               start = False

            continue

         if 'JPX Code' in r:
            # to create ONE target
            if num != 0:
               target = Target(jpxCd, instrument, qty)

               data['info'].append(target)

               # new target re-init
               target = {}
               instrument = {}
               qty = []
            else:
               data['date'] = date
               data['info'] = info

            num = num + 1
            start = True

            # data["info"]["jpxCd"]
            jpxCd = r.split(',')[1].strip()
            continue

         if start:
            # data["info"]["instrument"]
            if 'Instrument' in r:
               instrument = createInstrument(r)

            # data["info"]["qty"]
            else:
               items = list(map(str.strip, r.split(',')))

               # seller
               codes = np.array(traders)[:, 0].tolist()
               if items[0] not in codes:
                  traders.append([items[0], items[1], items[2]])

               # buyer
               codes = np.array(traders)[:, 0].tolist()
               if items[-4] not in codes:
                  traders.append([items[-4], items[-3], items[-2]])

               # quantity info
               qty.append([items[0], int(items[3]), items[-4], int(items[-1])])

   # write all data
   with codecs.open('test.json','w','utf-8') as f:
      f.write(json.dumps(data, default=default_method, ensure_ascii=False, indent=2, sort_keys=False, separators=(',', ': '))) # JPN utf-8, cls=TargetEncoder?

   # write all traders
   # [x.encode('utf-8') for x in traders]
   with codecs.open('traders.json','w','utf-8') as f:
      f.write(json.dumps(traders, ensure_ascii=False, indent=2, sort_keys=False, separators=(',', ': ')))

if __name__ == "__main__":
   main(sys.argv[1:])

