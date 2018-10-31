#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import sys
import requests
import re
from bs4 import BeautifulSoup

target_url = 'https://stocks.finance.yahoo.co.jp/stocks/detail/?code=1301'
try:
    r = requests.get(target_url)            #requestsを使って、webから取得
    soup = BeautifulSoup(r.text, 'lxml')    #要素を抽出 (lxml)

    stoksPrice = soup.find('td', class_='stoksPrice')
    stoksPrice = stoksPrice.find_next_sibling('td').text
    stoksPrice = float(re.sub('[,]', '', stoksPrice))
    print(stoksPrice)

    cnt = 0
    for dd in soup.find_all('dd', class_='ymuiEditLink mar0'):
        stng = dd.find('strong').text
        stng = float(re.sub('[,]', '', stng))
        print(stng)
        cnt += 1
        if cnt > 5:
            break


    # Debug
    '''
    for td in soup.find_all('td'):
        print(td.text.encode('cp932', 'ignore'))
        print(td.get('class'))
    '''

    #リンクを表示 (lxml)
    '''
    for a in soup.find_all('a'):
        print(a.get('href'))
    '''

except Exception as e:
    print("error: {0}".format(e), file=sys.stderr)
    exitCode = 2

### output
'''
3095.0 => 現値
3005.0 => 前日終値
3025.0 => 始値
3105.0 => 高値
3025.0 => 安値
26000.0 => 出来高
79571.0 => 売買代金 (x 1000 千円)
'''
