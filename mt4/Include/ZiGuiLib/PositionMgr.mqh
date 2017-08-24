//+------------------------------------------------------------------+
//|                                                  PositionMgr.mqh |
//|                                  Copyright 2017, Katokunou Corp. |
//|                                             http://katokunou.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "https://katokunou.com"
#property version   "1.00"
#property strict

#include <ZiGuiLib\Raspimt4Sym.mqh>
#include <ZiGuiLib\OrderStack.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PositionMgr
  {
private:
    Raspimt4Sym      sym;
    double           midRate;
    double           tradeVol;
    double           thresholdDelta;
    double           preTradedDelta[PositionType_ALL];
    OrderStack*      orderStack[PositionType_ALL];

public:
                     PositionMgr(Raspimt4Sym aSym, double aMidRate, double aVol, double aDelta);
                    ~PositionMgr();
    //
    Raspimt4Sym      getSym();
    //
    double           getMidRate();
    //
    void             setMidRate(double aMidRate);
    //
    double           getTradeVol();
    //
    double           getThresholdDelta();
    //
    void             setPreLtradedDelta(double preDelta);
    //
    double           getPreLtradedDelta();
    //
    void             setPreStradedDelta(double preDelta);
    //
    double           getPreStradedDelta();
    //
    void             getOrderStack(OrderStack*& aOrderStack[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionMgr::PositionMgr(Raspimt4Sym aSym, double aMidRate, double aVol, double aDelta)
  {
    this.sym = aSym;
    this.midRate = aMidRate;
    this.tradeVol = aVol;
    this.thresholdDelta = aDelta;

    this.preTradedDelta[LONG]  = -0.1;
    this.preTradedDelta[SHORT] = -0.1;

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
Raspimt4Sym PositionMgr::getSym()
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
double PositionMgr::getPreLtradedDelta()
  {
    return this.preTradedDelta[LONG];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::setPreLtradedDelta(double pre)
  {
    this.preTradedDelta[LONG] = pre;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PositionMgr::getPreStradedDelta()
  {
    return this.preTradedDelta[SHORT];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::setPreStradedDelta(double pre)
  {
    this.preTradedDelta[SHORT] = pre;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionMgr::getOrderStack(OrderStack*& aOrderStack[])
  {
    aOrderStack[LONG]  = this.orderStack[LONG];
    aOrderStack[SHORT]  = this.orderStack[SHORT];
  }
//+------------------------------------------------------------------+
