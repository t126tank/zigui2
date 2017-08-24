//+------------------------------------------------------------------+
//|                                                      Utility.mqh |
//|                                  Copyright 2017, Katokunou Corp. |
//|                                            https://katokunou.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "https://katokunou.com"
#property version   "1.00"
#property strict

#include <Object.mqh>
#include <ZiGuiLib\PositionType.mqh>

#ifndef Pi 
#define Pi 3.141592653589793238462643 
#endif
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Utility : public CObject
  {
private:

public:
                     Utility();
                    ~Utility();
    // b - buy: ask, s - sell: bid; spread = ask - sell > 0
    static double   calMidRate(const double s, const double b);
    // mid: middle rate, cur: current rate
    static double   calCurrentDelta(const double mid, const double cur, const double scale);
    // cur: current delta, pre: previous traded delta, vol: trade volumn, type: long/short
    static double   calTradeAmount(const double cur, const double pre, const double vol);
    // initDelta: init delta, vol: trade volumn, type: long/short
    static double   calInitTradeAmount(const double initDelta, const double vol);
   };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Utility::Utility()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Utility::~Utility()
  {
  }
//+------------------------------------------------------------------+
//| Returns the middle rate                                          |
//+------------------------------------------------------------------+
static double Utility::calMidRate(const double s, const double b)
  {
    return (s + b) / 2;
  }
//+------------------------------------------------------------------+
//| Returns Cumulative Normal Distribution result                    |
//| https://stackoverflow.com/questions/2328258/                     |
//|         cumulative-normal-distribution-function-in-c-c           |
//+------------------------------------------------------------------+
static double Utility::calCurrentDelta(const double mid, const double cur, const double scale)
  {
    double x = cur - mid;
    double L, K, w ;
    /* constants */
    double const a1 = 0.31938153, a2 = -0.356563782, a3 = 1.781477937;
    double const a4 = -1.821255978, a5 = 1.330274429;

    L = fabs(x);
    K = 1.0 / (1.0 + 0.2316419 * L);
    w = 1.0 - 1.0 / sqrt(2 * Pi) * exp(-L * L / 2) * (a1 * K + a2 * K *K + a3 * pow(K,3) + a4 * pow(K,4) + a5 * pow(K,5));

    if (x < 0) {
      w = 1.0 - w;
      w *= (1 - scale);
    } else {
      w *= (1 + scale);
    }
    return w;
  }
//+------------------------------------------------------------------+
//| Returns trading volumn for specified postion                     |
//+------------------------------------------------------------------+
static double Utility::calTradeAmount(const double cur, const double pre, const double vol)
  {
    double diff = cur - pre; // fabs(diff) >= threshlod delta [trade delta]
    
    return (2 * vol * diff);
  }
//+------------------------------------------------------------------+
//| Returns Init trading volumn for specified postion                |
//+------------------------------------------------------------------+
static double Utility::calInitTradeAmount(const double initDelta, const double vol)
  {
    return calTradeAmount(initDelta, 0, vol);
  }
//+------------------------------------------------------------------+
