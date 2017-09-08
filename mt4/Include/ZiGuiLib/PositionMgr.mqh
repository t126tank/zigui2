//+------------------------------------------------------------------+
//|                                                  PositionMgr.mqh |
//|                                  Copyright 2017, Katokunou Corp. |
//|                                             http://katokunou.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "https://katokunou.com"
#property version   "1.00"
#property strict

#include <ZiGuiLib\OrderStack.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PositionMgr
  {
private:
    string           sym;
    double           midRate;
    double           tradeVol;
    double           thresholdDelta;
    double           preTradedDelta;
    double           backupPreDelta;
    OrderStack*      orderStack[PositionType_ALL];

public:
                     PositionMgr(string aSym, double aMidRate, double aVol, double aDelta);
                    ~PositionMgr();
    //
    string           getSym();
    //
    double           getMidRate();
    //
    void             setMidRate(double aMidRate);
    //
    double           getTradeVol();
    //
    double           getThresholdDelta();
    //
    void             setPreTradedDelta(double preDelta);
    //
    double           getPreTradedDelta();
    //
    void             setBackupPreStradedDelta(double aBk);
    //
    double           getBackupPreStradedDelta();
    //
    void             getOrderStack(OrderStack*& aOrderStack[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionMgr::PositionMgr(string aSym, double aMidRate, double aVol, double aDelta)
  {
    this.sym = aSym;
    this.midRate = aMidRate;
    this.tradeVol = aVol;
    this.thresholdDelta = aDelta;

    this.preTradedDelta = -0.1;
    this.backupPreDelta = -0.1;

    this.orderStack[LONG]  = new OrderStack(LONG);
    this.orderStack[SHORT] = new OrderStack(SHORT);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionMgr::~PositionMgr()
  {
    this.orderStack[LONG].clear();
    delete this.orderStack[LONG];
    this.orderStack[SHORT].clear();
    delete this.orderStack[SHORT];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PositionMgr::getSym()
  {
    return this.sym;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionMgr::getMidRate()
  {
    return this.midRate;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::setMidRate(double aMidRate)
  {
    this.midRate = aMidRate;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionMgr::getTradeVol()
  {
    return this.tradeVol;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionMgr::getThresholdDelta()
  {
    return this.thresholdDelta;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionMgr::getPreTradedDelta()
  {
    return this.preTradedDelta;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::setPreTradedDelta(double aPre)
  {
    this.preTradedDelta = aPre;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionMgr::getBackupPreStradedDelta()
  {
    return this.backupPreDelta;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::setBackupPreStradedDelta(double aBk)
  {
    this.backupPreDelta = aBk;
  }//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::getOrderStack(OrderStack*& aOrderStack[])
  {
    aOrderStack[LONG]  = this.orderStack[LONG];
    aOrderStack[SHORT]  = this.orderStack[SHORT];
  }
//+------------------------------------------------------------------+
