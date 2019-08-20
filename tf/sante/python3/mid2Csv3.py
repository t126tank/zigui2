#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import csv
import datetime
import os
import re
import requests
import sys
from bs4 import BeautifulSoup

def main(argv):
    srcDir = "."

    if len(argv) != 0:
        srcDir = argv[0]
        os.chdir(srcDir)

    # コードを取る
    code = srcDir[7:11]

    # 日付を取る
    dt = datetime.datetime.today().strftime('%Y-%m-%d')
    # print(dt)

    year = datetime.datetime.today().strftime('%Y')
    # print(year)

    csvfile = 'stocks_' + code + '-T_1d_' + year + '.csv'
    # print(csvfile)

    target_url = 'https://jp.investing.com/indices/japan-ni225'
    ua = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0'
    headers = {'User-Agent': ua}

    try:
        r = requests.get(target_url, headers=headers) #requestsを使って、webから取得
        soup = BeautifulSoup(r.text, 'lxml')          #要素を抽出 (lxml)

        # <div class="top bold inlineblock">
        stoksPrice = soup.find('div', class_='top bold inlineblock')

        # <span class="arial_26 inlineblock pid-178-last" id="last_last" dir="ltr">20,677.22</span>
        stoksPrice = stoksPrice.find('span', id='last_last').text # find_next_sibling?
        stoksPrice = float(re.sub('[,]', '', stoksPrice))

        fields = []

        '''
        cnt = 0
        nums = []
        for dd in soup.find_all('dd', class_='ymuiEditLink mar0'):
            stng = dd.find('strong').text
            stng = float(re.sub('[,]', '', stng))
            # print(stng)
            nums.append(stng)

            cnt += 1
            if cnt > 5:
                break
        '''

        fields.append(str(dt))              # "tradeTime"
        fields.append(str(stoksPrice))      # "o"
        fields.append(str(stoksPrice))      # "h"
        fields.append(str(stoksPrice))      # "l"
        fields.append(str(stoksPrice))      # "c"
        fields.append('100')                # "volume"
        fields.append(str(stoksPrice))      # "modified p"

        # if last line isn't empty but has EOF
        with open(csvfile, 'r+') as f:
            # http://codepad.org/S3zjnKoD
            if f.readlines()[-1][-1:] != '\n':
                f.write('\n')

        with open(csvfile, 'a', newline='') as f:
            writer = csv.writer(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
            writer.writerow(fields)

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

if __name__ == "__main__":
   main(sys.argv[1:])

### output
'''
3095.0 => 現値/close
3005.0 => 0 前日終値
3025.0 => 1 始値
3105.0 => 2 高値
3025.0 => 3 安値
26000.0 => 4 出来高
79571.0 => 5 売買代金 (x 1000 千円)
'''
