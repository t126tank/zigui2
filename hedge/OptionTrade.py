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
    Target("https://www.jpx.co.jp/markets/derivatives/index.html", "https://svc.qri.jp/jpx/nkopm/"),
    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopm/1"),
    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopm/2"),
    Target("https://svc.qri.jp/jpx/nkopm/", "https://svc.qri.jp/jpx/nkopw/"),
    Target("https://svc.qri.jp/jpx/nkopw/", "https://svc.qri.jp/jpx/nkopw/1")
]

ipsilon1 = 0.2
ipsilon2 = 0.4

options = []

def intDelComma(str):
    rtn = 0
    if str.find("-") == -1:
        rtn = int(re.sub('[,]', '', str.strip()))

    return rtn

def convPrice(str):
    return int(re.sub('[,]', '', str.strip()))


def getPrices(str):
    val = re.split('[()]', str)

    sp = 99999
    if val[0].find("-") == -1:
        sp = convPrice(val[0])

    bp = 0
    if val[2].find("-") == -1:
        bp = convPrice(val[2])

    return sp, bp


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

        for idx,item in enumerate(tds):
            plus1 = idx + 1
            if plus1 % ITEM_NUM == 0:
                # print('ベガ <P>: ', item)
                atm = isATM(tds[idx-16])
                kp = getKp(tds[idx-16])

                csp, cbp = getPrices(tds[idx-20])
                # print("call::", csp, " :: ", intDelComma(tds[idx-24]), " :: ", cbp)
                options.append(Option("call", dd, kp, OptInfo(atm, intDelComma(tds[idx-24]), cbp, csp, convDelta(tds[idx-7])), tm, ts))

                psp, pbp = getPrices(tds[idx-12])
                # print("put::", psp, " :: ", intDelComma(tds[idx-8]), " :: ", pbp)
                options.append(Option("put",  dd, kp, OptInfo(atm, intDelComma(tds[idx-8]),  pbp, psp, convDelta(tds[idx-3])), tm, ts))
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
    return o.getInfo().getSp() < o.getInfo().getVal() and o.getInfo().getVal() > 0


def trade(o, t):
    limit1 = ipsilon2
    limit2 = ipsilon1
    if t == "long":
        limit1 = ipsilon1
        limit2 = ipsilon2

    if (
        (o.getInfo().getBp() > o.getInfo().getVal() and o.getInfo().getVal() > 0 and o.getInfo().getSp() < 100) or
        (o.getInfo().getBp() > 0 and o.getInfo().getSp() < 150)
       ):
        if (
            (o.getType() == "call" and o.getInfo().getDelta() < limit1) or
            (o.getType() == "put"  and abs(o.getInfo().getDelta()) < limit2)
           ):
            return True

def tradeL(o):
    # Long
    return trade(o, "long")


def tradeS(o):
    # Short
    return trade(o, "short")


def dbgPrint(o):
    val = o.getInfo().getVal()
    sp  = o.getInfo().getSp()
    bp  = o.getInfo().getBp()
    rateSp = round(val/sp - 1, 3)
    rateBp = '*' if bp == 0 else round(1 - val/bp, 3)

    print(o.getDd(), ' :: ', o.getKp(), ' :: ', o.getType(),    \
        ' :: (SELL)', sp,  \
        ' :: < (', rateSp,') :: (val) ', val,  \
        ' :: > (', rateBp,') :: (BUY) ', bp)

def main(argv):
    list(map(crawler, targets))

    print(">>> Common Buy:")
    optBs = list(filter(tradeB, options))
    list(map(dbgPrint, optBs))

    print(">>> Long:")
    optLs = list(filter(tradeL, options))
    list(map(dbgPrint, optLs))

    print(">>> Short")
    optSs = list(filter(tradeS, options))
    list(map(dbgPrint, optSs))

if __name__ == "__main__":
    main(sys.argv[1:])

'''
>>> Common Buy:
2019/01/10  ::  23625  ::  call  :: (SELL) 2  :: < ( 0.5 ) :: (val)  3  :: > ( -2.0 ) :: (BUY)  1
2019/01/10  ::  23500  ::  call  :: (SELL) 3  :: < ( 0.333 ) :: (val)  4  :: > ( -1.0 ) :: (BUY)  2
2019/01/10  ::  23375  ::  call  :: (SELL) 4  :: < ( 0.5 ) :: (val)  6  :: > ( -1.0 ) :: (BUY)  3
2019/01/10  ::  23250  ::  call  :: (SELL) 5  :: < ( 0.4 ) :: (val)  7  :: > ( -0.75 ) :: (BUY)  4
2019/01/10  ::  23125  ::  call  :: (SELL) 6  :: < ( 0.5 ) :: (val)  9  :: > ( -0.8 ) :: (BUY)  5
2019/01/10  ::  23000  ::  call  :: (SELL) 9  :: < ( 0.556 ) :: (val)  14  :: > ( -0.75 ) :: (BUY)  8
2019/01/10  ::  22875  ::  call  :: (SELL) 12  :: < ( 0.5 ) :: (val)  18  :: > ( -0.636 ) :: (BUY)  11
2019/01/10  ::  22750  ::  call  :: (SELL) 16  :: < ( 0.5 ) :: (val)  24  :: > ( -0.714 ) :: (BUY)  14
2019/01/10  ::  22625  ::  call  :: (SELL) 21  :: < ( 0.571 ) :: (val)  33  :: > ( -0.65 ) :: (BUY)  20
2019/01/10  ::  22500  ::  call  :: (SELL) 28  :: < ( 0.536 ) :: (val)  43  :: > ( -0.593 ) :: (BUY)  27
2019/01/10  ::  22375  ::  call  :: (SELL) 36  :: < ( 0.556 ) :: (val)  56  :: > ( -0.6 ) :: (BUY)  35
→ 看多，36 买价值 56 的call option，折价率 55.6%

2018/12/27  ::  20625  ::  call  :: (SELL) 515  :: < ( 0.233 ) :: (val)  635  :: > ( -0.351 ) :: (BUY)  470
>>> Long:
2019/01/10  ::  18750  ::  put  :: (SELL) 45  :: < ( -0.156 ) :: (val)  38  :: > ( 0.116 ) :: (BUY)  43
2019/01/10  ::  18500  ::  put  :: (SELL) 35  :: < ( -0.171 ) :: (val)  29  :: > ( 0.121 ) :: (BUY)  33
2019/01/10  ::  18250  ::  put  :: (SELL) 27  :: < ( -0.111 ) :: (val)  24  :: > ( 0.077 ) :: (BUY)  26
2019/02/07  ::  16000  ::  put  :: (SELL) 33  :: < ( -0.273 ) :: (val)  24  :: > ( 0.226 ) :: (BUY)  31
2019/02/07  ::  15000  ::  put  :: (SELL) 20  :: < ( -0.35 ) :: (val)  13  :: > ( 0.316 ) :: (BUY)  19
2019/02/07  ::  14000  ::  put  :: (SELL) 13  :: < ( -0.462 ) :: (val)  7  :: > ( 0.417 ) :: (BUY)  12
2019/02/07  ::  12000  ::  put  :: (SELL) 5  :: < ( -0.4 ) :: (val)  3  :: > ( 0.25 ) :: (BUY)  4
2019/03/07  ::  15500  ::  put  :: (SELL) 45  :: < ( -0.156 ) :: (val)  38  :: > ( 0.095 ) :: (BUY)  42
→ 看多，42 卖价值 38 的put option，溢价率 9.5%

2019/03/07  ::  15250  ::  put  :: (SELL) 40  :: < ( -0.175 ) :: (val)  33  :: > ( 0.108 ) :: (BUY)  37
2019/03/07  ::  15000  ::  put  :: (SELL) 35  :: < ( -0.143 ) :: (val)  30  :: > ( 0.091 ) :: (BUY)  33
2019/03/07  ::  14750  ::  put  :: (SELL) 31  :: < ( -0.161 ) :: (val)  26  :: > ( 0.103 ) :: (BUY)  29
2019/03/07  ::  14500  ::  put  :: (SELL) 28  :: < ( -0.179 ) :: (val)  23  :: > ( 0.08 ) :: (BUY)  25
2019/03/07  ::  14000  ::  put  :: (SELL) 22  :: < ( -0.182 ) :: (val)  18  :: > ( 0.1 ) :: (BUY)  20
2018/12/20  ::  20250  ::  put  :: (SELL) 33  :: < ( -0.152 ) :: (val)  28  :: > ( 0.034 ) :: (BUY)  29
>>> Short
2019/01/10  ::  18750  ::  put  :: (SELL) 45  :: < ( -0.156 ) :: (val)  38  :: > ( 0.116 ) :: (BUY)  43
2019/01/10  ::  18500  ::  put  :: (SELL) 35  :: < ( -0.171 ) :: (val)  29  :: > ( 0.121 ) :: (BUY)  33
2019/01/10  ::  18250  ::  put  :: (SELL) 27  :: < ( -0.111 ) :: (val)  24  :: > ( 0.077 ) :: (BUY)  26
2019/02/07  ::  16000  ::  put  :: (SELL) 33  :: < ( -0.273 ) :: (val)  24  :: > ( 0.226 ) :: (BUY)  31
→ 看空，31 卖价值 24 的put option，溢价率 22.6%

2019/02/07  ::  15000  ::  put  :: (SELL) 20  :: < ( -0.35 ) :: (val)  13  :: > ( 0.316 ) :: (BUY)  19
2019/02/07  ::  14000  ::  put  :: (SELL) 13  :: < ( -0.462 ) :: (val)  7  :: > ( 0.417 ) :: (BUY)  12
2019/02/07  ::  12000  ::  put  :: (SELL) 5  :: < ( -0.4 ) :: (val)  3  :: > ( 0.25 ) :: (BUY)  4
2019/03/07  ::  15500  ::  put  :: (SELL) 45  :: < ( -0.156 ) :: (val)  38  :: > ( 0.095 ) :: (BUY)  42
2019/03/07  ::  15250  ::  put  :: (SELL) 40  :: < ( -0.175 ) :: (val)  33  :: > ( 0.108 ) :: (BUY)  37
2019/03/07  ::  15000  ::  put  :: (SELL) 35  :: < ( -0.143 ) :: (val)  30  :: > ( 0.091 ) :: (BUY)  33
2019/03/07  ::  14750  ::  put  :: (SELL) 31  :: < ( -0.161 ) :: (val)  26  :: > ( 0.103 ) :: (BUY)  29
2019/03/07  ::  14500  ::  put  :: (SELL) 28  :: < ( -0.179 ) :: (val)  23  :: > ( 0.08 ) :: (BUY)  25
2019/03/07  ::  14000  ::  put  :: (SELL) 22  :: < ( -0.182 ) :: (val)  18  :: > ( 0.1 ) :: (BUY)  20
2018/12/20  ::  20250  ::  put  :: (SELL) 33  :: < ( -0.152 ) :: (val)  28  :: > ( 0.034 ) :: (BUY)  29
'''
