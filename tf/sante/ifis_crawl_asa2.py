#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import datetime
import json
import re
import sys
import csv
import time
import requests
import urllib3
from urllib3.exceptions import InsecureRequestWarning
from bs4 import BeautifulSoup

urllib3.disable_warnings(InsecureRequestWarning)


BASE_URL = "https://monex.ifis.co.jp/"

def hcCode():
  url = "http://127.0.0.1/ifis/ifis.php"
  resp = requests.get(url, verify=False)
  return "&hc=" + resp.text

# https://monex.ifis.co.jp/index.php?sa=consNews&date=0&stock_code=0&wd2=&sector=0&topix_type=0&topix_score=0
def ifisUrl(page_id, hc_code):
  arg0 = "index.php?"
  arg1 = "sa=consNews&date=0&stock_code=0&wd2=&sector=0&"
  arg2 = "topix_type=0&topix_score=0&"
  arg3 = "pageID=" + str(page_id)
  return BASE_URL + arg0 + arg1 + arg2 + arg3 + hc_code

def splitStock(s):
  nmcd = s.split("(")
  cd = re.sub('[)]', '', nmcd[1])
  return nmcd[0], cd

# "%Y%m%d%H%M%S"
now = datetime.datetime.now()

try:
  hc_code = hcCode()

  json_list = []
  json_data = {}

  n = 1
  endPage = -1
  while True:
    url = ifisUrl(n, hc_code)  # pageID=<n>

    headers = requests.utils.default_headers()
    headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0'
    })

    r = requests.get(url, headers=headers, verify=False)  #requestsを使って、webから取得
    soup = BeautifulSoup(r.text, 'lxml')                  #要素を抽出 (lxml)

    tm = datetime.datetime.now()
    ts = int(tm.timestamp())
    today = tm.strftime("%Y/%m/%d")

    # delivery date
    grp = soup.find_all('div', class_='group')

    # fields in each group
    for fields in grp:
      # print("debug: " + fields.text)
      if len(fields.text.strip()) == 0:
        continue

      row = []
      dt = fields.find('div', class_='date').find('span', class_='date_new')

      # if today not in dtTxt:
      if not dt:
        endPage = n
        break

      # 業績予想&レーティング
      img = fields.find('div', class_='type').find('img')
      src = img['src']
      p2 = 'ico_tpx_type_M_02.png'
      p7 = 'ico_tpx_type_M_07.png'
      if p2 not in src and p7 not in src:
        continue

      dtTxt = dt.text
      dtTxt = dtTxt[:10] + ' ' + dtTxt[10:]
      stock = fields.find('div', class_='stock')
      nm, cd = splitStock(stock.text)

      msg = fields.find('div', class_='title_link')
      urlLnk = 'http://stocks.finance.yahoo.co.jp/stocks/detail/?code=' + cd + '.T&d=6m'

      href = msg.find('a')['href']
      ctxLnk = 'https://monex.ifis.co.jp/' + href + '&' + hc_code

      row.append(dtTxt)
      row.append(cd)
      row.append(nm)
      row.append(msg.text)
      row.append(ctxLnk)
      row.append(urlLnk)
      json_list.append(row)

    # print(json_list)

    # if none "next page", then break this while loop in the end
    nextLnk = soup.find("a", title="next page")
    if nextLnk is None or n == endPage:
      # print("Last pageID is " + str(n))
      break

    # print("Current pageID is " + str(n))
    n += 1
    time.sleep(1)

  # write json
  # f = open(now.strftime("%Y%m%d") + ".json", "w")
  # f.write(json.dumps(list, ensure_ascii=False)) # JPN utf-8
  # f.close()

  json_data["業績ニュース(■業績予想&レーティング)"] = json_list
  # print(json_data)

  url_items = 'web送信API'
  json_str = json.dumps(json_data, ensure_ascii=False, indent=1).encode('utf-8')
  # print(json_str)
  # r_post = requests.post(url_items, json_str, headers={'Content-type': 'application/json; charset=utf8'})

except Exception as e:
    print("error: {0}".format(e), file=sys.stderr)
    exitCode = 2

