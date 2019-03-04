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
OPT_PUT  = "put"
OPT_CALL = "call"

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

ipsilon1 = 0.06
ipsilon2 = 0.11

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
        rtn = float(str.strip())
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
                options.append(Option(OPT_CALL, dd, kp, OptInfo(atm, intDelComma(tds[idx-24]), cbp, csp, convDelta(tds[idx-7])), tm, ts))

                psp, pbp = getPrices(tds[idx-12])
                # print("put::", psp, " :: ", intDelComma(tds[idx-8]), " :: ", pbp)
                options.append(Option(OPT_PUT,  dd, kp, OptInfo(atm, intDelComma(tds[idx-8]),  pbp, psp, convDelta(tds[idx-3])), tm, ts))
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
    ret1 = o.getInfo().getSp() < o.getInfo().getVal() and o.getInfo().getVal() > 0
    ret2 = o.getInfo().getSp() < 150

    return (ret1 and ret2)

def trade(o, t):
    limit1 = max(abs(ipsilon2), abs(ipsilon1))
    limit2 = min(abs(ipsilon2), abs(ipsilon1))
    type   = OPT_PUT

    if t == "long":
        limit1, limit2 = limit2, limit1
        type   = OPT_CALL

    # Sell chance
    ret1 = (o.getInfo().getBp() > o.getInfo().getVal() and o.getInfo().getVal() > 0)

    # Low risk sell chance
    ret2 = ((o.getType() == OPT_CALL and o.getInfo().getDelta() < limit1) or
            (o.getType() == OPT_PUT  and abs(o.getInfo().getDelta()) < limit2))

    # Hedge chance
    ret3 = False
    # ret3 = (o.getInfo().getBp() > 0 and o.getInfo().getSp() < 150 and o.getType() == type)

    return (ret1 or ret2 or ret3)
 
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
    rateSp = '*' if val == 0 else round(sp/val - 1, 3)
    rateBp = '*' if val == 0 else round(bp/val - 1, 3)

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

    print(">>> Short:")
    optSs = list(filter(tradeS, options))
    list(map(dbgPrint, optSs))

if __name__ == "__main__":
    main(sys.argv[1:])

'''
>>> Common Buy:
2019/03/07  ::  21750  ::  put  :: (SELL) 130  :: < ( -0.422 ) :: (val)  225  :: > ( -0.444 ) :: (BUY)  125
2019/03/07  ::  21625  ::  put  :: (SELL) 84  :: < ( -0.458 ) :: (val)  155  :: > ( -0.471 ) :: (BUY)  82
2019/03/07  ::  21500  ::  put  :: (SELL) 55  :: < ( -0.5 ) :: (val)  110  :: > ( -0.518 ) :: (BUY)  53
2019/03/07  ::  21375  ::  put  :: (SELL) 36  :: < ( -0.526 ) :: (val)  76  :: > ( -0.539 ) :: (BUY)  35
2019/03/07  ::  21250  ::  put  :: (SELL) 24  :: < ( -0.529 ) :: (val)  51  :: > ( -0.549 ) :: (BUY)  23
2019/03/07  ::  21125  ::  put  :: (SELL) 17  :: < ( -0.528 ) :: (val)  36  :: > ( -0.556 ) :: (BUY)  16
2019/03/07  ::  21000  ::  put  :: (SELL) 12  :: < ( -0.538 ) :: (val)  26  :: > ( -0.577 ) :: (BUY)  11
2019/03/07  ::  20875  ::  put  :: (SELL) 9  :: < ( -0.526 ) :: (val)  19  :: > ( -0.579 ) :: (BUY)  8
→ 看空，9 买价值 19 的 put option，折价率 52.6%

2019/03/20  ::  21000  ::  put  :: (SELL) 79  :: < ( -0.506 ) :: (val)  160  :: > ( -0.537 ) :: (BUY)  74
>>> Long:
2019/03/07  ::  25750  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  24000  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  23250  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  23125  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  23000  ::  call  :: (SELL) 2  :: < ( 1.0 ) :: (val)  1  :: > ( 0.0 ) :: (BUY)  1
2019/03/07  ::  22875  ::  call  :: (SELL) 2  :: < ( 0.0 ) :: (val)  2  :: > ( -0.5 ) :: (BUY)  1
2019/03/07  ::  22750  ::  call  :: (SELL) 3  :: < ( 0.5 ) :: (val)  2  :: > ( 0.0 ) :: (BUY)  2
2019/03/07  ::  22625  ::  call  :: (SELL) 4  :: < ( 0.333 ) :: (val)  3  :: > ( 0.0 ) :: (BUY)  3
2019/03/07  ::  22500  ::  call  :: (SELL) 7  :: < ( 0.75 ) :: (val)  4  :: > ( 0.5 ) :: (BUY)  6
2019/03/07  ::  22375  ::  call  :: (SELL) 12  :: < ( 1.0 ) :: (val)  6  :: > ( 0.833 ) :: (BUY)  11
2019/03/07  ::  22250  ::  call  :: (SELL) 21  :: < ( 0.75 ) :: (val)  12  :: > ( 0.667 ) :: (BUY)  20
→ 看多，20 卖价值 12 的 call option，溢价率 66.7%

2019/03/20  ::  21750  ::  call  :: (SELL) 315  :: < ( 1.1 ) :: (val)  150  :: > ( 0.967 ) :: (BUY)  295
>>> Short:
2019/03/07  ::  25750  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  24000  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  23250  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  23125  ::  call  :: (SELL) 1  :: < ( 0.0 ) :: (val)  1  :: > ( -1.0 ) :: (BUY)  0
2019/03/07  ::  23000  ::  call  :: (SELL) 2  :: < ( 1.0 ) :: (val)  1  :: > ( 0.0 ) :: (BUY)  1
2019/03/07  ::  22875  ::  call  :: (SELL) 2  :: < ( 0.0 ) :: (val)  2  :: > ( -0.5 ) :: (BUY)  1
2019/03/07  ::  22750  ::  call  :: (SELL) 3  :: < ( 0.5 ) :: (val)  2  :: > ( 0.0 ) :: (BUY)  2
2019/03/07  ::  22625  ::  call  :: (SELL) 4  :: < ( 0.333 ) :: (val)  3  :: > ( 0.0 ) :: (BUY)  3
2019/03/07  ::  22500  ::  call  :: (SELL) 7  :: < ( 0.75 ) :: (val)  4  :: > ( 0.5 ) :: (BUY)  6
2019/03/07  ::  22375  ::  call  :: (SELL) 12  :: < ( 1.0 ) :: (val)  6  :: > ( 0.833 ) :: (BUY)  11
2019/03/07  ::  22250  ::  call  :: (SELL) 21  :: < ( 0.75 ) :: (val)  12  :: > ( 0.667 ) :: (BUY)  20
2019/03/07  ::  22125  ::  call  :: (SELL) 37  :: < ( 0.85 ) :: (val)  20  :: > ( 0.8 ) :: (BUY)  36
→ 看空，36 卖价值 20 的 put option，溢价率 80%
'''
