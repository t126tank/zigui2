#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function
from __future__ import division

import csv
import datetime
import os
import re
import requests
import sys

from bs4 import BeautifulSoup
from time import sleep

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

    year  = int(datetime.datetime.today().strftime('%Y'))
    month = int(datetime.datetime.today().strftime('%m'))
    # print(year)

    for y in range(1985, year+1):
        for m in range (12):
            mon = m + 1
            # good data was from 1985y-3m-25d
            if y == 1985 and mon < 4:
                continue

            if y == year and mon > month:
                break   # over current month

            csvfile = 'stocks_' + code + '-T_1d_' + str(y) + '.csv'
            # print(csvfile)
            lines = []
            cnt = 0

            target_url = 'https://indexes.nikkei.co.jp/nkave/statistics/dataload?list=daily&year=' + str(y) + '&month=' + str(mon)

            #debug
            print("download ... " + str(y) + str(mon))
            sleep(2)  # not too heavy to access

            try:
                r = requests.get(target_url)            #requestsを使って、webから取得
                soup = BeautifulSoup(r.text, 'lxml')    #要素を抽出 (lxml)

                tbl = soup.find('table', class_='table_size100per')

                for td in tbl.find_all('td', class_='list-row-dashed'):
                    tt = td.text
                    if cnt < 5:
                        if mon == 1: # add titles
                            lines.append(str(tt)) # titles
                        else:
                            cnt += 1
                            continue  # ignore titles from Feb
                    else:
                        if cnt % 5 == 0:
                            lines.append(re.sub('\.', '-', tt))
                        elif cnt % 5 != 0:
                            lines.append(float(re.sub(',', '', tt)))

                    cnt += 1

                    if cnt % 5 == 0:
                        if cnt < 6 and mon == 1:
                            lines.append("vol")
                            lines.append("avg")
                        else:
                            lines.append(1)
                            lines.append(round((lines[2]+lines[3]+lines[4]+lines[4])/4, 2)) # h+l+c+c/4

                        with open(csvfile, 'a', newline='') as f:
                            writer = csv.writer(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
                            writer.writerow(lines)

                        lines = []

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
