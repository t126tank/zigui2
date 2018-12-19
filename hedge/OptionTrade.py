#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import csv
import datetime
import os
import re
import requests
import urllib3
from urllib3.exceptions import InsecureRequestWarning
urllib3.disable_warnings(InsecureRequestWarning)
import sys
from bs4 import BeautifulSoup

ITEM_NUM = 25

class OptInfo:
    def __init__(self, atm, val, bp, sp, delta=0.02, iv=1.1, gama=2.2):
        self.atm   = atm
        self.val   = val
        self.bp    = bp
        self.sp    = sp
        self.delta = delta
        self.iv    = iv
        self.gama  = gama # // Delta, Gamma, Theta, Vega

    def getAtm(self):
        return self.atm

    def getVal(self):
        return self.val

    def getBp(self):
        return self.bp

    def getSp(self):
        return self.sp

    def getDelta(self):
        return self.delta

    def getIv(self):
        return self.iv

    def getGamma(self):
        return self.gamma


class Option:
    def __init__(self, type, dd, kp, info, tm, ts):
        self.type = type
        self.dd   = dd
        self.kp   = kp
        self.info = info
        self.tm   = tm
        self.ts   = ts

    def getType(self):
        return self.type

    def getDd(self):
        return self.dd

    def getKp(self):
        return self.kp

    def getInfo(self):
        return self.info

    def getTm(self):
        return self.tm

    def getTs(self):
        return self.ts

class Target:
    def __init__(self, ref, tgt):
        self.ref = ref
        self.tgt = tgt

    def getRef(self):
        return self.ref

    def getTgt(self):
        return self.tgt

targets = [
#    Target("https://www.jpx.co.jp/markets/derivatives/index.html", "https://svc.qri.jp/jpx/nkopm/"),
#    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopm/1"),
#    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopm/2"),
#    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopw/"),
    Target("https://svc.qri.jp/jpx/nkopw/", "https://svc.qri.jp/jpx/nkopw/1")
]

ipsilon1 = 0.05
ipsilon2 = 0.07

options = []

def intDelComma(str):
    rtn = 0
    if str.find("-") == -1:
        rtn = int(re.sub('[,]', '', str.strip()))

    return rtn


def convDelta(str):
    rtn = 1.0
    try:
        rtn = float(str)
    except:
        return rtn

    return rtn


def getKp(str):
    rtn = re.sub('[,|リスク指標|A T M]', '', str.strip())
    return int(rtn.strip())


def isATM(str):
    return str.find("A T M") != -1


def crawler(t):
    headers = requests.utils.default_headers()
    headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0',
        'Referer': t.getRef()
    })

    try:
        r = requests.get(t.getTgt(), headers=headers, verify=False) #requestsを使って、webから取得
        soup = BeautifulSoup(r.text, 'lxml')                        #要素を抽出 (lxml)

        tm = datetime.datetime.now()
        ts = int(tm.timestamp())

        # delivery date
        dd = soup.find('div', class_='date-table last-tradingday').find('dd').text

        # regex = re.compile('.*listing-col-.*')
        # soup.find_all("div", {"class" : regex}):
        # for td in soup.find(class_='price-info-scroll').find_all('td', class_='a-right'):
        # for td in soup.find(class_='price-info-scroll').select('td[class*="a-right"]'):

        tds = []
        for td in soup.find(class_='price-info-scroll').find_all('td', {'class':['a-right', 'a-center']}):
            tds.append(td.text)
            # print(td.text)

        options = []
        for idx,item in enumerate(tds):
            plus1 = idx + 1
            if plus1 % ITEM_NUM == 0:
                # print('ベガ <P>: ', item)
                atm = isATM(tds[idx-16])
                kp = getKp(tds[idx-16])

                options.append(Option("call", dd, kp, OptInfo(atm, intDelComma(tds[idx-24]), 12, 8, convDelta(tds[idx-7])), tm, ts))
                options.append(Option("put",  dd, kp, OptInfo(atm, intDelComma(tds[idx-8]),  12, 8, convDelta(tds[idx-3])), tm, ts))
            ''' 
            elif plus1 % ITEM_NUM == 1:
                print('清算値 <C>: ', item)
            elif plus1 % ITEM_NUM == 2:
                print('建玉残 <C>: ', item)
            elif plus1 % ITEM_NUM == 3:
                print('取引高 <C>: ', item)
            elif plus1 % ITEM_NUM == 4:
                print('売気配IV - 買気配IV <C>: ', item)
            elif plus1 % ITEM_NUM == 5:
                print('売気配(数量) - 買気配(数量) <C>: ', item)
            elif plus1 % ITEM_NUM == 6:
                print('IV <C>: ', item)
            elif plus1 % ITEM_NUM == 7:
                print('前日比 <C>: ', item)
            elif plus1 % ITEM_NUM == 8:
                print('現在値 <C>: ', item)
            elif plus1 % ITEM_NUM == 9:
                print('KP: ', item)
            elif plus1 % ITEM_NUM == 10:
                print('現在値 <P>: ', item)
            elif plus1 % ITEM_NUM == 11:
                print('前日比 <P>: ', item)
            elif plus1 % ITEM_NUM == 12:
                print('IV <P>: ', item)
            elif plus1 % ITEM_NUM == 13:
                print('売気配(数量) - 買気配(数量) <P>: ', item)
            elif plus1 % ITEM_NUM == 14:
                print('売気配IV - 買気配IV <P>: ', item)
            elif plus1 % ITEM_NUM == 15:
                print('取引高 <P>: ', item)
            elif plus1 % ITEM_NUM == 16:
                print('建玉残 <P>: ', item)
            elif plus1 % ITEM_NUM == 17:
                print('清算値 <P>: ', item)
            elif plus1 % ITEM_NUM == 18:
                print('デルタ <C>: ', item)
            elif plus1 % ITEM_NUM == 19:
                print('ガンマ <C>: ', item)
            elif plus1 % ITEM_NUM == 20:
                print('セータ <C>: ', item)
            elif plus1 % ITEM_NUM == 21:
                print('ベガ <C>: ', item)
            elif plus1 % ITEM_NUM == 22:
                print('デルタ <P>: ', item)
            elif plus1 % ITEM_NUM == 23:
                print('ガンマ <P>: ', item)
            else:
                print('セータ <P>: ', item)
            ''' 

    except Exception as e:
        print("error: {0}".format(e), file=sys.stderr)
        exitCode = 2

def tradeB(o):
    # Common Buy
    if o.getInfo().getSp() < o.getInfo().getVal() and o.getInfo().getVal() != 0:
        return True

def tradeL(o):
    if o.getInfo().getBp() > o.getInfo().getVal() and o.getInfo().getVal() != 0:
        # Long
        if (
            (o.getType() == "call" and o.getInfo().getDelta() < ipsilon1) or
            (o.getType() == "put"  and abs(o.getInfo().getDelta()) < ipsilon2)
           ):
            return True

def tradeS(o):
    if o.getInfo().getBp() > o.getInfo().getVal() and o.getInfo().getVal() != 0:
        # Short
        if (
            (o.getType() == "call" and o.getInfo().getDelta() < ipsilon2) or
            (o.getType() == "put"  and abs(o.getInfo().getDelta()) < ipsilon1)
           ):
            return True

def dbgPrint(o):
    print(o.getDd(), ' :: ', o.getKp(), ' :: ', o.getType(), ' :: ', o.getInfo().getVal)

def main(argv):
    list(map(crawler, targets))

    print(">>> Common Buy")
    optBs = list(filter(tradeB, options))
    list(map(dbgPrint, optBs))

    print(">>> Long")
    optLs = list(filter(tradeL, options))
    list(map(dbgPrint, optLs))

    print(">>> Short")
    optSs = list(filter(tradeS, options))
    list(map(dbgPrint, optSs))

if __name__ == "__main__":
    main(sys.argv[1:])
