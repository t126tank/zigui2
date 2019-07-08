#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function

import csv
import datetime
import json
import numpy as np
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
    def __init__(self, atm, val, bp, sp, delta, iv, biv=12.12, siv=13.13, gama=2.2):
        self.atm   = atm
        self.val   = val
        self.bp    = bp
        self.sp    = sp
        self.delta = delta
        self.biv   = biv
        self.siv   = siv
        self.iv    = iv
        self.gama  = gama # // Delta, Gamma, Theta, Vega

    def isAtm(self):
        return self.atm

    def getVal(self):
        return self.val

    def getBp(self):
        return self.bp

    def getSp(self):
        return self.sp

    def getDelta(self):
        return self.delta

    def getBiv(self):
        return self.biv

    def getSiv(self):
        return self.siv

    def getIv(self):
        return self.iv

    def getGamma(self):
        return self.gamma

class OptionEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Option):
            return obj.strftime('%Y/%m/%d')
        return super(OptionEncoder, self).default(obj) # 他の型はdefaultのエンコード方式を使用

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

tm = datetime.datetime.now()
ts = 0

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

def getIvs(str):
    ivs = str.replace("-", "0%")
    val = re.split('%', ivs)

    return float(val[0]), float(val[1])


def convDelta(str):
    rtn = 1.0

    try:
        rtn = float(str.strip())
    except:
        return rtn

    return rtn


def getKp(str):
    rtn = re.sub('[,|リスク指標|ATM]', '', str.strip())
    return int(rtn.strip())


def isATM(str):
    return str.find("ATM") != -1


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
                kpStr = tds[idx-16].replace(u"\xa0",u"")
                atm = isATM(kpStr)
                kp = getKp(kpStr)

                ### callOpt info
                csp, cbp = getPrices(tds[idx-20])
                # print("call::", csp, " :: ", intDelComma(tds[idx-24]), " :: ", cbp)

                csiv, cbiv = getIvs(tds[idx-21])
                # common call iv
                # print("call::", tds[idx-19])
                options.append(Option(OPT_CALL, dd, kp, OptInfo(atm, intDelComma(tds[idx-24]), cbp, csp, convDelta(tds[idx-7]), tds[idx-19].replace("-", "0%"), cbiv, csiv), tm, ts))

                ### putOpt info
                psp, pbp = getPrices(tds[idx-12])
                # print("put::", psp, " :: ", intDelComma(tds[idx-8]), " :: ", pbp)

                psiv, pbiv = getIvs(tds[idx-11])
                # common put iv
                # print("put::", tds[idx-13])
                options.append(Option(OPT_PUT,  dd, kp, OptInfo(atm, intDelComma(tds[idx-8]),  pbp, psp, convDelta(tds[idx-3]), tds[idx-13].replace("-", "0%"), pbiv, psiv), tm, ts))
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
    iv  = o.getInfo().getIv()

    rateSp = '*' if val == 0 else round(sp/val - 1, 3)
    rateBp = '*' if val == 0 else round(bp/val - 1, 3)

    print(o.getDd(), ' :: ', o.getKp(), ' :: ', o.getType(),  \
        ' :: (SELL)', sp,  \
        ' :: < (', rateSp,') :: (val) ', val, ' :: (IV) ', iv, \
        ' :: > (', rateBp,') :: (BUY) ', bp)


def smilesData():
    atm = 0
    smiles = []
    smilesMap = {}

    for opt in options:
        info = opt.getInfo()

        # find ATM price for ALL options
        if atm == 0 and info.isAtm():
            atm = opt.getKp()

        # {20190523, call} - [kp, bp, sp, biv, siv]
        key = json.dumps({"end": opt.getDd(), "type": opt.getType()})
        if key not in smilesMap:
          smilesMap.setdefault(key, [])

        biv = info.getBiv()
        siv = info.getSiv()
        if biv > 0 and siv > 0:
            smilesMap[key].append([opt.getKp(), info.getBp(), info.getSp(), biv, siv])

    # transpose map & sorting by k-price
    for key, value in smilesMap.items():
        keyObj = json.loads(key)
        e = re.sub('[\/]', '', keyObj["end"])
        t = keyObj["type"]

        tmp = np.array(value)
        #
        # 先頭の列でソート
        #
        s = tmp[tmp[:,0].argsort(), :].transpose().tolist()

        smiles.append({"end": e, "type": t, "smile": s})

    return atm, smiles


def main(argv):
    ts = int(tm.timestamp())

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

    optObj   = {}
    optObj["ts"] = ts

    optObj["atm"], optObj["data"] = smilesData()

    # write json
    f = open(str(ts) + ".json", "w")
    f.write(json.dumps(optObj, cls=OptionEncoder, ensure_ascii=False, indent=2, sort_keys=False, separators=(',', ': '))) # JPN utf-8
    f.close()


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
