//+------------------------------------------------------------------+
//|                                                 HedgeRequest.mqh |
//|                                  Copyright 2017, Katokunou Corp. |
//|                                             http://katokunou.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "https://katokunou.com"
#property version   "1.00"
#property strict

#include <ZiGuiLib\PositionType.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class HedgeRequest
  {
private:
    bool             tradeFlg;
    double           tradeAmount[PositionType_ALL];

public:
                     HedgeRequest(bool aFlg, const double& aAmount[]);
                    ~HedgeRequest();
    //
    bool             isTrade();
    //
    void             getTradeAmount(double& aAmount[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HedgeRequest::HedgeRequest(bool aFlg, const double& aAmount[])
  {
    this.tradeFlg = aFlg;
    this.tradeAmount[LONG]  = aAmount[LONG];
    this.tradeAmount[SHORT] = aAmount[SHORT];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HedgeRequest::~HedgeRequest()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HedgeRequest::isTrade()
  {
    return this.tradeFlg;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HedgeRequest::getTradeAmount(double& aAmount[])
  {
    aAmount[LONG]  = this.tradeAmount[LONG];
    aAmount[SHORT] = this.tradeAmount[SHORT];
  }
//+------------------------------------------------------------------+
