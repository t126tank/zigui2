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
    Target("https://www.jpx.co.jp/markets/derivatives/index.html", "https://svc.qri.jp/jpx/nkopm/"),
    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopm/1"),
    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopm/2"),
    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopw/"),
    Target("https://svc.qri.jp/jpx/nkopw/", "https://svc.qri.jp/jpx/nkopw/1")
]

ipsilon1 = 0.05
ipsilon2 = 0.07

options = []

def crawler(t):
    headers = requests.utils.default_headers()
    headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0',
        'Referer': t.getRef()
    })

    try:
        r = requests.get(t.getTgt(), headers=headers, verify=False) #requestsを使って、webから取得
        soup = BeautifulSoup(r.text, 'lxml')                        #要素を抽出 (lxml)

        # delivery date
        dd = soup.find('div', class_='date-table last-tradingday').find('dl dd')
        print(dd)

        tm = datetime.datetime.now()
        ts = int(tm.timestamp())

        optInfo = OptInfo(True, 10, 12, 8, 0.02)
        option  = Option("call", "2018/12/28", 21000, optInfo, tm, ts)

        options.append(option)

    except Exception as e:
        print("error: {0}".format(e), file=sys.stderr)
        exitCode = 2

def tradeB(o):
    # Common Buy
    if o.getInfo().getSp() < o.getInfo().getVal():
        return True

def tradeL(o):
    if o.getInfo().getBp() > o.getInfo().getVal():
        # Long
        if (
            (o.getType() == "call" and o.getInfo().getDelta() < ipsilon1) or
            (o.getType() == "put"  and abs(o.getInfo().getDelta()) < ipsilon2)
           ):
            return True

def tradeS(o):
    if o.getInfo().getBp() > o.getInfo().getVal():
        # Short
        if (
            (o.getType() == "call" and o.getInfo().getDelta() < ipsilon2) or
            (o.getType() == "put"  and abs(o.getInfo().getDelta()) < ipsilon1)
           ):
            return True

def printTm(o):
    print(o.getTm())

def main(argv):
    list(map(crawler, targets))

    print(">>> Common Buy")
    optBs = list(filter(tradeB, options))
    list(map(printTm, optBs))

    print(">>> Long")
    optLs = list(filter(tradeL, options))
    list(map(printTm, optLs))

    print(">>> Short")
    optSs = list(filter(tradeS, options))
    list(map(printTm, optSs))

if __name__ == "__main__":
    main(sys.argv[1:])
