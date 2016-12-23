// ZiGuiHedge.mqh   Version 0.01

#property copyright "Copyright (c) 2016, abc"
#property link      "http://aabbccc.com/"

#include <Object.mqh>
#include <ZiGuiLib\RakutenSym.mqh>


#define ZIGUI_CORRELATION  "ZiGuiIndicators\\Correlation"
#define MaxBars            3

#define Lots               0.1

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct ZiGuiHedgePair {
    string sym;
    int  pos;       // order ticket
    int  magic_b;   // magic number of buy
    double slOrd;   // stop loss
    double tpOrd;   // take profits
    double pipPoint;    // pips adjustment
    double slippagePips;// slippage
};

struct ZiGuiHedgePara {
   int RShort; // Correlation Short period
   int RLong;  // Correlation Long period
   double RThreshold;   // Correlation threshold (-80, +80)
   double RIndicatorN;  // reserved
   double Entry;        // Ex: Momentum abs(diff) > +80 or < -80 - OPEN
   double TIndicatorN;  // Ex: Trade indicator period - 14
   double TakeProfits;  // StopLoss?
   double Step;         // Trailing Stop step width
   double Exit;         // Ex: Momentum abs(diff) < +30 or > -30 - CLOSE

   // NOT FOR DATA MINING
   double RPeriod;      // default: PERIOD_D1
   double TPeriod;      // defalut: PERIOD_M5
};

struct ZiGuiHedgeIndicator {
   // long/short correlation
   double rShort[MaxBars];
   double rLong[MaxBars];

   // open/close indicators' buffer: momentum etc
   double buf0[MaxBars];
   double buf1[MaxBars];
};

//+------------------------------------------------------------------+
//| MAIN CLASS                                                       |
//+------------------------------------------------------------------+
class ZiGuiHedge : public CObject
  {
private:
   int                  idx;
   int                  pos;
   double               lots;
   double               times;       // Ex: ZARJPY vs USDJPY
   bool                 corrlation;  // true: positive, false: negative
   ZiGuiHedgePara       para;
   ZiGuiHedgeIndicator  indicator;

public:
                     ZiGuiHedge(string aPair1, string aPair2);
                    ~ZiGuiHedge(void);
   //--- methods set
   void              setZiGuiHedgePara(const ZiGuiHedgePara &aPara);
   void              setIndex(int aIdx)      { idx = aIdx; };
   void              setLots(double aLots)   { lots = aLots; };
   //--- methods get
   ZiGuiHedgePair       zgp[2];
//    ZiGuiHedgePair    getZiGuiHedgePair(int aIdx)     { return zgp[aIdx]; }; // ONLY Class Object has pointer
   //--- method indicators
   void              refreshIndicators(void);
   //--- method trade
   void              trade(void);
private:
   //--- method signal
   int               entrySignal();
   int               exitSignal();
protected:
   //--- method others
   int               Compare(const CObject *node,const int mode=0) const;
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
ZiGuiHedge::ZiGuiHedge(string aPair1, string aPair2)
  {
      zgp[0].sym = aPair1;
      zgp[1].sym = aPair2;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
ZiGuiHedge::~ZiGuiHedge(void)
  {
  }
//+------------------------------------------------------------------+
//| Refresh Indicator for Hedge sigals                               |
//+------------------------------------------------------------------+
void ZiGuiHedge::refreshIndicators(void)
  {
   for (int i = 0; i < MaxBars; i++)
   {
      indicator.rShort[i] = iCustom(NULL, para.RPeriod, ZIGUI_CORRELATION,
         zgp[0].sym, zgp[1].sym, para.RShort, 0, 0);
      indicator.rLong[i]  = iCustom(NULL, para.RPeriod, ZIGUI_CORRELATION,
         zgp[0].sym, zgp[1].sym, para.RLong,  0, 0);

      indicator.buf0[i] = iMomentum(zgp[0].sym, para.TPeriod, para.TIndicatorN, PRICE_CLOSE, 0);
      indicator.buf1[i] = iMomentum(zgp[1].sym, para.TPeriod, para.TIndicatorN, PRICE_CLOSE, 0);
   }
  }
//+------------------------------------------------------------------+
//| Trade based on Hedge sigals                                      |
//+------------------------------------------------------------------+
void ZiGuiHedge::trade(void)
  {
   int sig_entry = entrySignal();
   bool deal = false;

   // Open Signals
   if (sig_entry > 0) {
      int s = 2-sig_entry;
      int b = sig_entry-1;

//      while (!deal) {
         deal = MyOrderSend2(b, zgp[b].sym, OP_BUY, Lots, 0, 0, 0, zgp[b].sym);
//      }

      deal = false;
//      while (!deal) {
        deal =  MyOrderSend2(s, zgp[s].sym, OP_SELL, Lots, 0, 0, 0, zgp[s].sym);
//      }
   }

   // Close Signals
   if (sig_entry < 0) {
//      while (!deal) {
         deal = MyOrderClose(0);
//      }

      deal = false;
//      while (!deal) {
         deal = MyOrderClose(1);
//      }
   }
  }
//+------------------------------------------------------------------+
//| Generate entry signal for buying                                 |
//| Open Signals > 0 or Close Signals < 0                            |
//| -1: Close Pair1 and Pair2                                        |
//|  1: buy Pair1 and sell Pair2                                     |
//|  2: buy Pair2 and sell Pair1                                     |
//+------------------------------------------------------------------+
int ZiGuiHedge::entrySignal(void)
 {
   int ret = 0;

   double delta = MathAbs(indicator.buf0[0] - indicator.buf1[0]);
   static datetime oldTime[];

   // Send monitor mail during generating new Bar
   if (oldTime[idx] == 0)
      oldTime[idx] = Time[0];
   else if (oldTime[idx] < Time[0]) {
      oldTime[idx] = Time[0];
      SendMail("MT4 Hedge: " + oldTime[idx],
         "delta = " + delta + ", " +
         "Pair1[0] = " + indicator.buf0[0] + ", " +
         "Pair2[0] = " + indicator.buf1[0] + ", " +
         "Correlation[0] = " + indicator.rShort[0]);
   }

   // Up/Dn trends (rShort vs rLong) + Positive/Negative
   if (indicator.rShort[0] > para.RThreshold &&
       delta > para.Entry) {
      if (indicator.buf0[0] > indicator.buf1[0])
         ret = 2;
      else
         ret = 1;

      // corrlation = true; // inverse or mirroring AND RThreshold * (-1)
   }

   // 
   if (delta < para.Exit) {
      ret = -1;
   }
   return(ret);
 }
//+------------------------------------------------------------------+
//| Generate entry signal for buying                                 |
//| Open Signals > 0 or Close Signals < 0                            |
//| -1: Close Pair1 and Pair2                                        |
//|  1: buy Pair1 and sell Pair2                                     |
//|  2: buy Pair2 and sell Pair1                                     |
//+------------------------------------------------------------------+
int ZiGuiHedge::exitSignal(void)
 {
   return(0);
 }

void ZiGuiHedge::setZiGuiHedgePara(const ZiGuiHedgePara &aPara)
 {
   para.RShort = aPara.RShort;
   para.RLong  = aPara.RLong;
   para.RThreshold  = aPara.RThreshold;
   para.RIndicatorN = aPara.RIndicatorN;
   para.Entry = aPara.Entry;
   para.TIndicatorN = aPara.TIndicatorN;
   para.TakeProfits = aPara.TakeProfits;
   para.Step = aPara.Step;
   para.Exit = aPara.Exit;

   para.RPeriod = aPara.RPeriod;
   para.TPeriod = aPara.TPeriod;
 }
