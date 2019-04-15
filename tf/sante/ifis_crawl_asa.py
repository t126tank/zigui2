#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import datetime
import json
#import re
import sys
import csv
import time
import requests
import urllib3
from urllib3.exceptions import InsecureRequestWarning
urllib3.disable_warnings(InsecureRequestWarning)
#from bs4 import BeautifulSoup

BASE_URL = "https://monex.ifis.co.jp/"

def hcCode():
  url = "https://127.0.0.1/ifis/ifis.php"
  resp = requests.get(url, verify=False)
  return "&hc=" + resp.text


# https://monex.ifis.co.jp/index.php?sa=screenRankDetail4csv&ta=p&scid=7
def ifisUrl(hc_code):
  arg0 = "index.php?"
  arg1 = "sa=screenRankDetail4csv&"
  arg2 = "ta=p&scid=7"

  return BASE_URL + arg0 + arg1 + arg2 + hc_code

def isTarget(r):
  try:
    comp = float(r[6])
    cons = float(r[7])

    return comp > 4.9 or cons > 4.9

  except Exception as e:
    # print("error: {0}".format(e), file=sys.stderr)
    return False


# "%Y%m%d%H%M%S"
now = datetime.datetime.now()

try:
  json_list = []
  json_data = {}
  with requests.Session() as s:
    download = s.get(ifisUrl(hcCode()))

    decoded_content = download.content.decode('shift-jis')

    cr = csv.reader(decoded_content.splitlines(), delimiter=',')
    my_list = list(cr)

    isTitle = True
    myIndices = [0, 1, 2, 6, 7]
    for row in my_list:
      if isTitle or isTarget(row):
        myRow = [row[i] for i in myIndices]

        if not isTitle:
          urlLnk = 'http://stocks.finance.yahoo.co.jp/stocks/detail/?code=' + myRow[0] + '.T&d=6m'
          myRow.append(urlLnk)

        isTitle = False

        print(myRow)
        json_list.append(myRow)


  # write json
  # f = open(now.strftime("%Y%m%d") + ".json", "w")
  # f.write(json.dumps(list, ensure_ascii=False)) # JPN utf-8
  # f.close()

  url_items = 'メール送信 WebAPI'
  json_data["経常利益予想コンセンサス上昇ランキング"] = json_list
  # print(json_data)

  json_str = json.dumps(json_data, ensure_ascii=False, indent=1).encode('utf-8')
  # print(json_str)
  r_post = requests.post(url_items, json_str, headers={'Content-type': 'application/json; charset=utf8'})

except Exception as e:
    print("error: {0}".format(e), file=sys.stderr)
    exitCode = 2

