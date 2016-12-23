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
   int               getIndex(void)          { return idx;};
   //--- method indicators
   void              refreshIndicators(void);
   //--- method trade
   void              trade(void);
private:
   //--- method signal
   int               entrySignal();
   int               exitSignal();
   bool              MyOrderSend2(int pos_id, int type, double lots,
                                  double price, double sl, double tp,
                                  string comment="");
   bool              MyOrderClose2(int pos_id);
   int               MyOrderType2(int pos_id);
   double            MyOrderOpenLots2(int pos_id);
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
         deal = MyOrderSend2(b, OP_BUY, Lots, 0, 0, 0, zgp[b].sym);
//      }

      deal = false;
//      while (!deal) {
        deal =  MyOrderSend2(s, OP_SELL, Lots, 0, 0, 0, zgp[s].sym);
//      }
   }

   // Close Signals
   if (sig_entry < 0) {
//      while (!deal) {
         deal = MyOrderClose2(0);
//      }

      deal = false;
//      while (!deal) {
         deal = MyOrderClose2(1);
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
   static datetime oldTime[SYM_LAST];

   // Send monitor mail during generating new Bar
   if (oldTime[idx] == 0)
      oldTime[idx] = Time[0];
   else if (oldTime[idx] < Time[0]) {
      oldTime[idx] = Time[0];
      SendMail("MT4 time: " + oldTime[idx] + " hedge idx: " + idx,
         "delta = " + delta + ", " +
         "Pair1[" + zgp[0].sym + "] = " + indicator.buf0[0] + ", " +
         "Pair2[" + zgp[1].sym + "] = " + indicator.buf1[0] + ", " +
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

//+------------------------------------------------------------------+
//| Set parameters of ZiGuiHedgePara                                 |
//+------------------------------------------------------------------+
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
 
//+------------------------------------------------------------------+
//| Send Order 2                                                     |
//+------------------------------------------------------------------+
bool ZiGuiHedge::MyOrderSend2(int pos_id, int type, double lots,
                 double price, double sl, double tp,
                 string comment="")
{
   if (MyOrderType2(pos_id) != OP_NONE) return(true);
   // for no order
   double d = MarketInfo(zgp[pos_id].sym, MODE_DIGITS);
   price = NormalizeDouble(price, d); // Digits
   sl = NormalizeDouble(sl, d);
   tp = NormalizeDouble(tp, d);

   // market price
   if(type == OP_BUY)  price = MarketInfo(zgp[pos_id].sym, MODE_ASK);
   if(type == OP_SELL) price = MarketInfo(zgp[pos_id].sym, MODE_BID); // Bid;
   
   int ret = OrderSend(zgp[pos_id].sym, type, lots, price,
                zgp[pos_id].slippagePips, 0, 0, comment,
                zgp[pos_id].pos, 0, ArrowColor[type]);
   if(ret == -1)
   {
      int err = GetLastError();
      Print("MyOrderSend : ", err, " " ,
            ErrorDescription(err));
      return(false);
   }

   // show open position
   zgp[pos_id].pos = ret;

   // send SL and TP orders
   if(sl > 0) zgp[pos_id].slOrd = sl;
   if(tp > 0) zgp[pos_id].tpOrd = tp;
   return(true);
}

//+------------------------------------------------------------------+
//| send close order 2                                               |
//+------------------------------------------------------------------+
bool ZiGuiHedge::MyOrderClose2(int pos_id)
{
   if (MyOrderOpenLots2(pos_id) == 0) return(true);
   // for open position

   int type = MyOrderType2(pos_id);
   bool ret = OrderClose(zgp[pos_id].pos, OrderLots(),
                 OrderClosePrice(), Slippage,
                 ArrowColor[type]);
   if(!ret)
   {
      int err = GetLastError();
      Print("MyOrderClose : ", err, " ",
            ErrorDescription(err));
      return(false);
   }
   zgp[pos_id].pos = 0;
   return(true);
}

//+------------------------------------------------------------------+
//| get order type                                                   |
//+------------------------------------------------------------------+
int ZiGuiHedge::MyOrderType2(int pos_id)
{
   int type = OP_NONE;

   if (zgp[pos_id].pos > 0 &&
       OrderSelect(zgp[pos_id].pos, SELECT_BY_TICKET))
      type = OrderType();

   return(type);
}

//+------------------------------------------------------------------+
//| get signed lots of open position                                 |
//+------------------------------------------------------------------+
double ZiGuiHedge::MyOrderOpenLots2(int pos_id)
{
   int type = MyOrderType2(pos_id);
   double lots = 0;
   if(type == OP_BUY) lots = OrderLots();
   if(type == OP_SELL) lots = -OrderLots();
   return(lots);   
}
