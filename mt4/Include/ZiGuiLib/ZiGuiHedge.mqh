// ZiGuiHedge.mqh   Version 0.01

#property copyright "Copyright (c) 2016, abc"
#property link      "http://aabbccc.com/"

#include <Object.mqh>
#include <ZiGuiLib\RakutenSym.mqh>


//+------------------------------------------------------------------+
//| 定数定義                                                         |
//+------------------------------------------------------------------+
#define MAX_RETRY_TIME   10.0 // 秒
#define SLEEP_TIME        0.1 // 秒
#define MILLISEC_2_SEC 1000.0 // ミリ秒
#define ZIGUI_CORRELATION  "ZiGuiIndicators\\Correlation"
#define MaxBars            3
#define HOST_IP            "katokunou.com"
#define HOST_PORT          80

MqlNet INet;

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
   double               times;      // Ex: 10 - ZARJPY(1.0 lots) vs USDJPY(0.1 lots)
   bool                 corrlation; // true: positive, false: negative
   bool                 isTSStarted;
   ZiGuiHedgePara       para;
   ZiGuiHedgeIndicator  indicator;

public:
                     ZiGuiHedge(string aPair1, string aPair2);
                    ~ZiGuiHedge(void);
   //--- methods set
   void              setZiGuiHedgePara(const ZiGuiHedgePara &aPara);
   void              setIndex(int aIdx)      { idx = aIdx; };
   void              setLots(double aLots)   { lots = aLots; };
   void              setTSStarted(bool aflg) { isTSStarted = aflg; };   // trailing-stop started flag
   //--- methods get
   ZiGuiHedgePair       zgp[2];
//    ZiGuiHedgePair    getZiGuiHedgePair(int aIdx)     { return zgp[aIdx]; }; // ONLY Class Object has pointer
   int               getIndex(void)          { return idx;};
   bool              isHedgeOpening();
   bool              isBothHedgeOpening();
   bool              isHalfHedgeOpening();
   //--- method indicators
   void              refreshIndicators(void);
   //--- method trade
   void              trade(void);
private:
   //--- method signal
   int               entrySignal();
   int               exitSignal();
   bool              MyOrderSend2(int pos_id, int type,
                                  double price, double sl, double tp,
                                  string comment="");
   bool              MyOrderClose2(int pos_id);
   int               MyOrderType2(int pos_id);
   double            MyOrderOpenLots2(int pos_id);
   bool              MyOrderTS(int pos_id);  // Trailing-Stop
   bool              orderModifyReliable(int aTicket, double aPrice, double aStoploss, double aTakeprofit, datetime aExpiration, color aArrow_color = CLR_NONE);
//   int               make_request(datetime time, int ticket, string op, double price, string type, double lots,  double profits);
   int               make_request(int pos_id, string op);
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
   int b = 0, s = 1;

   // Open Signals
   if (sig_entry > 0) {
      b = sig_entry-1;
      s = 2-sig_entry;

      do {
   //      while (!deal) {
            // ❶ close -> open ❷ open -> keep open ❸ ts (opening) -> keep ts
            deal = MyOrderSend2(b, OP_BUY, 0, zgp[b].slOrd, zgp[b].tpOrd, zgp[b].sym); // NOT specify stop-loss NOR take-profits
   //      }

         deal = false;
   //      while (!deal) {
           deal =  MyOrderSend2(s, OP_SELL, 0, zgp[s].slOrd, zgp[s].tpOrd, zgp[s].sym);
   //      }
      } while (!isBothHedgeOpening()); // secure both pairs open
   }

   if (isHalfHedgeOpening())
      isTSStarted = true;

   // Close Signals OR hedge is on trailing-stop
   if (sig_entry < 0 || isTSStarted) {
      isTSStarted = true;

      MyOrderTS(b);
      MyOrderTS(s);

#ifdef originalclose
//      while (!deal) {
         deal = MyOrderClose2(b);
//      }

      deal = false;
//      while (!deal) {
         deal = MyOrderClose2(s);
//      }
#endif
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

   // Hedge pairs should be opened simultaneously
   if (!isHedgeOpening()) {
      isTSStarted = false; // Both pairs are CLOSE so not on tailing-stop for either

      // Up/Dn trends (rShort vs rLong) + Positive/Negative
      if (indicator.rShort[0] > para.RThreshold &&
          delta > para.Entry) {
         if (indicator.buf0[0] > indicator.buf1[0])
            ret = 2;
         else
            ret = 1;
   
         // corrlation = true; // inverse or mirroring AND RThreshold * (-1)
      }
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
//| Judge Hedge Pair is Opening or not                               |
//+------------------------------------------------------------------+
bool ZiGuiHedge::isHedgeOpening()
 {
   bool ret = false;
   if (zgp[0].pos > 0 || zgp[1].pos > 0)
      ret = true;

   return (ret);
 }
//+------------------------------------------------------------------+
//| Judge Hedge Pair is BOTH Opening or not                          |
//+------------------------------------------------------------------+
bool ZiGuiHedge::isBothHedgeOpening()
 {
   bool ret = false;
   if (zgp[0].pos > 0 && zgp[1].pos > 0)
      ret = true;

   return (ret);
 }
//+------------------------------------------------------------------+
//| Judge Hedge Pair is XOR Opening or not                           |
//+------------------------------------------------------------------+
bool ZiGuiHedge::isHalfHedgeOpening(void)
 {
   bool ret = false;
   if ((zgp[0].pos > 0  && zgp[1].pos == 0) ||
       (zgp[0].pos == 0 && zgp[1].pos >  0))
      ret = true;

   return (ret);
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
//| Send Order2 for Open                                                     |
//+------------------------------------------------------------------+
bool ZiGuiHedge::MyOrderSend2(int pos_id, int type,
                 double price, double sl, double tp,
                 string comment="")
{
   if (MyOrderType2(pos_id) != OP_NONE) return(true);
   // for no order
   string sym = zgp[pos_id].sym;
   double d = MarketInfo(sym, MODE_DIGITS);
   price = NormalizeDouble(price, d); // Digits
   sl = NormalizeDouble(sl, d);
   tp = NormalizeDouble(tp, d);

   // market price
   if (type == OP_BUY)  price = MarketInfo(sym, MODE_ASK);
   if (type == OP_SELL) price = MarketInfo(sym, MODE_BID); // Bid;
   
   int ret = OrderSend(sym, type, lots, price,
               zgp[pos_id].slippagePips, 0, 0, comment,
               zgp[pos_id].magic_b, 0, ArrowColor[type]);
   if (ret == -1)
   {
      int err = GetLastError();
      Print("MyOrderSend : ", err, " " ,
            ErrorDescription(err));
      zgp[pos_id].pos = 0;
      return(false);
   }

   // show open position
   zgp[pos_id].pos = ret;

   // Post Order info
   string opStr = "sell";
   if (type == OP_BUY)
      opStr = "buy";
   make_request(pos_id, opStr);

   // send SL and TP orders
   if (sl > 0) zgp[pos_id].slOrd = sl;
   if (tp > 0) zgp[pos_id].tpOrd = tp;
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
   if (!ret)
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
   double l = 0;
   if (type == OP_BUY)  l =  OrderLots();
   if (type == OP_SELL) l = -OrderLots();
   return(l);
}

//+------------------------------------------------------------------+
//| trailing-stop                                                    |
//+------------------------------------------------------------------+
bool ZiGuiHedge::MyOrderTS(int pos_id)
{
   if (MyOrderOpenLots2(pos_id) == 0) return(true);
   // (!((MyOrderOpenLots2(pos_id) > 0) || (MyOrderOpenLots2(pos_id) < 0))) due to double type

   // for open position
   int type = MyOrderType2(pos_id);
   string sym = zgp[pos_id].sym;
   double digits = MarketInfo(sym, MODE_DIGITS);

   double oPrice    = NormalizeDouble(OrderOpenPrice(), digits);
   double oStopLoss = NormalizeDouble(OrderStopLoss(),  digits);
   int    oTicket   = zgp[pos_id].pos; // OrderTicket();
   double stopLevel = MarketInfo(sym, MODE_STOPLEVEL) *
                        MarketInfo(sym, MODE_POINT);

   if (type == OP_BUY)
   {
      double price          = MarketInfo(sym, MODE_BID);
      double modifyStopLoss = iHigh(sym, para.TPeriod, iHighest(sym, para.TPeriod, MODE_HIGH, para.TIndicatorN, 1));

      if (price - modifyStopLoss >= stopLevel) {
         if (modifyStopLoss > oStopLoss) {
            orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, ArrowColor[type]);
         }
      }
   } else if (type == OP_SELL) {
      // iLowはBidで算出。ショートの決済はAskになるので、スプレッドを足す必要がある
      price          = MarketInfo(sym, MODE_ASK);
      modifyStopLoss = iLow(sym, para.TPeriod, iLowest(sym, para.TPeriod, MODE_LOW, para.TIndicatorN, 1)) +
                        MarketInfo(sym, MODE_SPREAD);

      // ショートの場合、条件式にoStopLoss == 0.0が必要
      // oStopLoss = 0.0の場合、modifyStopLossには価格（正の値）が格納されるため、
      // modifyStopLoss < oStopLossの条件が永久に成立しなくなるため
      if (modifyStopLoss - price >= stopLevel) {
         if (modifyStopLoss < oStopLoss || oStopLoss == 0.0) {
            orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, ArrowColor[type]);
         }
      }
   }

   return(true);
}

//+------------------------------------------------------------------+
//|【関数】信頼できる注文変更                                        |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aTicket            チケット番号                  |
//|         ○      aPrice             待機注文の新しい仕掛け価格    |
//|         ○      aStoploss          損切り価格                    |
//|         ○      aTakeprofit        利食い価格                    |
//|         ○      aExpiration        待機注文の有効期限            |
//|         △      aArrow_color       チャート上の矢印の色          |
//|                                                                  |
//|【戻値】true ：正常終了                                           |
//|        false：異常終了                                           |
//|                                                                  |
//|【備考】△：既定値あり                                            |
//+------------------------------------------------------------------+
bool ZiGuiHedge::orderModifyReliable(int aTicket, double aPrice, double aStoploss, double aTakeprofit, datetime aExpiration, color aArrow_color = CLR_NONE)
{
   bool result = false;

   int startTime = GetTickCount();

   Print("Attempted orderModifyReliable(#" + aTicket + ", " + aPrice + ", SL:"+ aStoploss + ", TP:" + aTakeprofit + ", Expiration:" + TimeToStr(aExpiration) + ", ArrowColor:" + aArrow_color + ")");

   bool selected = OrderSelect(aTicket, SELECT_BY_TICKET, MODE_TRADES);

   string symbol = OrderSymbol();
   int    type   = OrderType();

   double digits = MarketInfo(symbol, MODE_DIGITS);

   double price      = NormalizeDouble(OrderOpenPrice(), digits);
   double stoploss   = NormalizeDouble(OrderStopLoss(), digits);
   double takeprofit = NormalizeDouble(OrderTakeProfit(), digits);

   aPrice      = NormalizeDouble(aPrice,      digits);
   aStoploss   = NormalizeDouble(aStoploss,   digits);
   aTakeprofit = NormalizeDouble(aTakeprofit, digits);

   double stopLevel   = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
   double freezeLevel = MarketInfo(symbol, MODE_FREEZELEVEL) * MarketInfo(symbol, MODE_POINT);

   while (true) {
      if (IsStopped()) {
         Print("Trading is stopped!");
         return(false);
      }

      if (GetTickCount() - startTime > MAX_RETRY_TIME * MILLISEC_2_SEC) {
         Print("Retry attempts maxed at " + MAX_RETRY_TIME + "sec");
         return(false);
      }

      double ask = NormalizeDouble(MarketInfo(symbol, MODE_ASK), digits);
      double bid = NormalizeDouble(MarketInfo(symbol, MODE_BID), digits);

      // 仕掛け／損切り／利食いがストップレベル未満かフリーズレベル以下の場合、エラー
      if (type == OP_BUY) {
         if (MathAbs(bid - aStoploss) < stopLevel) {
            Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aTakeprofit - bid) < stopLevel) {
            Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(bid - aStoploss) <= freezeLevel) {
            Print("FreezeLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aTakeprofit - bid) <= freezeLevel) {
            Print("FreezeLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         }
      } else if (type == OP_SELL) {
         if (MathAbs(aStoploss - ask) < stopLevel) {
            Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(ask - aTakeprofit) < stopLevel) {
            Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aStoploss - ask) <= freezeLevel) {
            Print("FreezeLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(ask - aTakeprofit) <= freezeLevel) {
            Print("FreezeLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         }
      } else if (type == OP_BUYLIMIT) {
         if (MathAbs(ask - aPrice) < stopLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aPrice - aStoploss) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))) {
            Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aTakeprofit - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))) {
            Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(ask - aPrice) <= freezeLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         }
      } else if (type == OP_SELLLIMIT) {
         if (MathAbs(aPrice - bid) < stopLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aStoploss - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))) {
            Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aPrice - aTakeprofit) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))) {
            Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aPrice - bid) <= freezeLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         }
      } else if (type == OP_BUYSTOP) {
         if (MathAbs(aPrice - ask) < stopLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aPrice - aStoploss) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))) {
            Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aTakeprofit - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))) {
            Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aPrice - ask) <= freezeLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         }
      } else if (type == OP_SELLSTOP) {
         if (MathAbs(bid - aPrice) < stopLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aStoploss - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))) {
            Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(aPrice - aTakeprofit) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))) {
            Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         } else if (MathAbs(bid - aPrice) <= freezeLevel && (aPrice != 0.0 && aPrice != price)) {
            Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
            return(false);
         }
      }

      if (IsTradeContextBusy()) {
         Print("Must wait for trade context");
      } else {
         result = OrderModify(aTicket, aPrice, aStoploss, aTakeprofit, aExpiration, aArrow_color);
         if (result) {
            Print("Success! Ticket #", aTicket, " order modified, details follow");
            selected = OrderSelect(aTicket, SELECT_BY_TICKET, MODE_TRADES);
            OrderPrint();
            return(result);
         }

         int err = GetLastError();

         // 一時的エラーの場合はリトライするが、恒常的エラーの場合は処理中断（リトライしてもエラーになるため）
         if (err == ERR_NO_ERROR || 
            err == ERR_COMMON_ERROR ||
            err == ERR_SERVER_BUSY ||
            err == ERR_NO_CONNECTION ||
            err == ERR_TRADE_TIMEOUT ||
            err == ERR_INVALID_PRICE ||
            err == ERR_PRICE_CHANGED ||
            err == ERR_OFF_QUOTES ||
            err == ERR_BROKER_BUSY ||
            err == ERR_REQUOTE ||
            err == ERR_TRADE_CONTEXT_BUSY) {
            Print("Temporary Error: " + err + " " + ErrorDescription(err) + ". waiting");
         } else {
            Print("Permanent Error: " + err + " " + ErrorDescription(err) + ". giving up");
            return(result);
         }

         // 最適化とバックテスト時はリトライは不要
         if (IsOptimization() || IsTesting()) {
            return(result);
         }
      }

      Sleep(SLEEP_TIME * MILLISEC_2_SEC);
  }

  return(result);
}
//+------------------------------------------------------------------+
//| trailing-stop                                                    |
//+------------------------------------------------------------------+
int ZiGuiHedge::make_request(int pos_id, string op) {
   OrderSelect(zgp[pos_id].pos, SELECT_BY_TICKET);

   int d = (int) MarketInfo(zgp[pos_id].sym, MODE_DIGITS);
   //Create the client request. This is in JSON format but you can send any string
   string request =  "{\"time\":  \""
            + TimeToStr(OrderOpenTime()) + "\","
            + " \"ticket\": \""
            + IntegerToString(zgp[pos_id].pos) + "\","
            + " \"op\": \""
            + op + "\","
            + " \"price\": \""
            + DoubleToStr(OrderOpenPrice(), d) + "\","
            + " \"symbol\": \""
            + Symbol() + "\","
            + " \"type\": \""
            + "open" + "\","
            + " \"lots\": \""
            + DoubleToStr(MyOrderOpenLots2(pos_id), d) + "\","
            + " \"profits\": \""
            + DoubleToStr(OrderProfit(), d) + "\"}";

   //Create the response string
   string response = "";

   //Make the connection
   if (!INet.Open(HOST_IP, HOST_PORT)) return(-1);

   if (!INet.RequestJson("POST", "/ifis/mt4/hedge-post.php", response, false, true, request, false)) {
      // printDebug("-Err download ");
      return(-1);
   }
   // Print(request);
   return(0);
}

