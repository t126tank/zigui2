// Raspimt4_EA_hedge.mq4
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "http://katokunou.com/"

#include <ZiGuiLib\PositionMgr.mqh>
#include <ZiGuiLib\Utility.mqh>

input double MidRate    = 109.483;
input double TradeVol   = 3.33;
input double ThresholdDelta = 0.003888;
input double ScaleCDF   = 0.03;

#include <ZiGuiLib\PositionMgr.mqh>
#define POSITIONS    (1 * 2)  // hedge pair positions * 2
#include <ZiGuiLib\MyPosition.mqh>
#include <ZiGuiLib\HedgeRequest.mqh>

#define REFRESH   (2 * 60 * 60) // 3H
int Magic = 20170822;

PositionMgr* pMgr;
Utility*     utility;
datetime initTime;

int init()
{
   initTime = TimeCurrent();
   utility = new Utility();
   pMgr = new PositionMgr(USDJPY, MidRate, TradeVol, ThresholdDelta);

   // MyInitPosition(Magic);
   return(0);
}

void deinit()
{
   closeAllOrders();
   delete pMgr;
   delete utility;
}

int start()
{
   // MyCheckPosition();

   HedgeRequest* tmp = getHedgeRequest();
   if (tmp.isTrade()) {
      int orderId;
      double tradeAmount[PositionType_ALL];
      tmp.getTradeAmount(tradeAmount);

      OrderStack* orderStack[PositionType_ALL];
      pMgr.getOrderStack(orderStack);

      // Initial
      if (tradeAmount[LONG] > 0 && tradeAmount[SHORT] > 0) {
         MyOrderSend2(orderStack, OP_BUY, tradeAmount[LONG], 0, 0, 0, "LONG");
         MyOrderSend2(orderStack, OP_SELL, tradeAmount[SHORT], 0, 0, 0, "SHORT");
      } else { // On hedging
         double lots;
         double remaining;

         // close LONG  / open SHORT for (tradeAmount[LONG] < 0)
         remaining = (tradeAmount[LONG] < 0)? -tradeAmount[LONG]: -tradeAmount[SHORT];
         while (remaining > 0) {
            orderId = (tradeAmount[LONG] < 0)? orderStack[LONG].peek(): orderStack[SHORT].peek();
            lots = MyOrderLots2(orderId);
            if (lots <= remaining) {
               MyOrderClose2(orderStack, orderId);
               remaining -= lots;
            } else {
               MyOrderCloseParts2(orderStack, orderId, remaining);
               remaining = 0;
            }
         }
         if (tradeAmount[LONG] < 0) { // close LONG  / open SHORT
            MyOrderSend2(orderStack, OP_SELL, tradeAmount[SHORT], 0, 0, 0, "SHORT");
         } else {
            MyOrderSend2(orderStack, OP_BUY,  tradeAmount[LONG],  0, 0, 0, "LONG");
         }
      }

      // TODO: debug
      orderStack[LONG].display();
      orderStack[SHORT].display();
   }

   delete tmp;

   // REFRESH
   if ((TimeCurrent() - initTime) > REFRESH) {
      initTime = TimeCurrent();
      restartEpoch();
   }

   return(0);
}

void closeAllOrders() {
      OrderStack* orderStack[PositionType_ALL];
      pMgr.getOrderStack(orderStack);

      while (orderStack[LONG].peek() > 0)
         MyOrderClose2(orderStack, orderStack[LONG].peek());

      while (orderStack[SHORT].peek() > 0)
         MyOrderClose2(orderStack, orderStack[SHORT].peek());
}

void restartEpoch() {
   // closeAllOrders();
   // delete pMgr;

   // TODO: use offical mid rate
   // pMgr = new PositionMgr(USDJPY, MidRate, TradeVol, ThresholdDelta);
   string sym = Raspimt4SymStr[pMgr.getSym()];
   double currentMidRate = utility.calMidRate(MarketInfo(sym, MODE_BID), MarketInfo(sym, MODE_ASK));
   // pMgr.setMidRate(currentMidRate);

Print(" Refresh time is " + TimeToStr(initTime, TIME_DATE | TIME_SECONDS) + " @ " + currentMidRate);
}

HedgeRequest* getHedgeRequest() {
   bool tradeFlg = false;
   string sym = Raspimt4SymStr[pMgr.getSym()];
   double currentMidRate = utility.calMidRate(MarketInfo(sym, MODE_BID), MarketInfo(sym, MODE_ASK));
   double currentDelta = utility.calCurrentDelta(pMgr.getMidRate(), currentMidRate, ScaleCDF); // SHORT
   double curLongDelta = 1 - currentDelta;

   double tradeAmount[PositionType_ALL];
   tradeAmount[SHORT] = utility.calInitTradeAmount(currentDelta, pMgr.getTradeVol());
   tradeAmount[LONG]  = utility.calInitTradeAmount(curLongDelta, pMgr.getTradeVol());

   // TODO: FIRST TRADING for OPENNING BOTH
   if (pMgr.getPreLtradedDelta() < 0 && pMgr.getPreStradedDelta() < 0) {
      // assume traded delta is in (0, 1)

PrintFormat("Init: [%f]  %s", currentDelta, "SHORT");
PrintFormat("Init: [%f]  %s", curLongDelta, "LONG");

      tradeFlg = true;
   } else {
      // TODO: what type is currentDelta for SHORT?
      if (fabs(currentDelta - pMgr.getPreStradedDelta()) >= fabs(pMgr.getThresholdDelta())) {
         tradeAmount[SHORT] = utility.calTradeAmount(currentDelta, pMgr.getPreStradedDelta(), pMgr.getTradeVol());
         tradeAmount[LONG]  = utility.calTradeAmount(curLongDelta, pMgr.getPreLtradedDelta(), pMgr.getTradeVol());

         // TODO: debug
         tradeAmount[SHORT] = NormalizeDouble(fabs(tradeAmount[SHORT]) < 0.01? 
                              tradeAmount[SHORT] < 0? -0.01: 0.01
                              : tradeAmount[SHORT], 2);
         tradeAmount[LONG] = NormalizeDouble(fabs(tradeAmount[LONG]) < 0.01?
                              tradeAmount[LONG] < 0? -0.01: 0.01
                              : tradeAmount[LONG], 2);
PrintFormat("Trade: [%f]  %s", fabs(currentDelta - pMgr.getPreStradedDelta()) - fabs(pMgr.getThresholdDelta()), "diff delta");
PrintFormat("Slot: [%f]  %s", tradeAmount[SHORT], "SHORT");
PrintFormat("Slot: [%f]  %s", tradeAmount[LONG],  "LONG");

         bool isDay = false;
         if (Hour() >= 1 && Hour() < 23)
            isDay = true;
         tradeFlg = true && isDay;
      }
   }
   if (tradeFlg) {
      pMgr.setPreStradedDelta(currentDelta);
      pMgr.setPreLtradedDelta(curLongDelta);
   }
   return new HedgeRequest(tradeFlg, tradeAmount);
}

void printSummary(void)
{
   PrintFormat("[%d][0]  %s: OK", 555, "555");
}

// send order to open position
bool MyOrderSend2(OrderStack*& aOrderStack[], int type, double lots,
                 double price, double sl, double tp,
                 string comment="")
{
   bool rtn = true;

   price = NormalizeDouble(price, Digits);
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);

   // market price
   RefreshRates();
   if (type == OP_BUY) price = Ask;
   if (type == OP_SELL) price = Bid;
   
   int ret = OrderSend(Raspimt4SymStr[pMgr.getSym()], type, lots, price,
                Slippage*10, 0, 0, comment,
                Magic, 0, ArrowColor[type]); // TODO: handle magic
   if (ret == -1)
   {
      int err = GetLastError();
      Print("MyOrderSend : ", err, " " ,
            ErrorDescription(err));
      rtn = false;
   }
   else
   {
      // push open orderId
      if (type == OP_BUY) {
         aOrderStack[LONG].push(ret);
      } else {
         aOrderStack[SHORT].push(ret);
      }
   }
   // send SL and TP orders
   // if(sl > 0) SLorder[pos_id] = sl;
   // if(tp > 0) TPorder[pos_id] = tp;

   return(rtn);
}

// send close order
bool MyOrderClose2(OrderStack*& aOrderStack[], int orderId)
{
   bool rtn = true;
   if (MyOrderOpenLots2(orderId) == 0)
      return(rtn);

   // for open position
   int type = MyOrderType2(orderId);

   RefreshRates();
   bool ret = OrderClose(orderId, OrderLots(),
                 OrderClosePrice(), Slippage*10,
                 ArrowColor[type]);

   if (!ret)
   {
      int err = GetLastError();
      Print("MyOrderClose : ", err, " ",
            ErrorDescription(err));
      rtn = false;
   } else {
      // pop open orderId
      if (type == OP_BUY) {
         aOrderStack[LONG].pop();
      } else {
         aOrderStack[SHORT].pop();
      }
   }
   return(rtn);
}

// partial closed order id
int getNewTicketNumber(double aOpenPrice, datetime aOpenTime, int aType)
{
   int rtn = -1;
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderOpenTime() == aOpenTime &&
             OrderOpenPrice() == aOpenPrice &&
             OrderType() == aType) {
            rtn = OrderTicket();
         }
      }
   }
   return rtn;
}

// send close order for parts
bool MyOrderCloseParts2(OrderStack*& aOrderStack[], int orderId, double parts)
{
   bool rtn = true;
   if (MyOrderOpenLots2(orderId) == 0)
      return(rtn);

   // for open position
   int type = MyOrderType2(orderId);

PrintFormat("MyOrderCloseParts2: [%d] (%f -- %f)", orderId, MyOrderLots2(orderId), parts);
   RefreshRates();
   bool ret = OrderClose(orderId, parts,
                 OrderClosePrice(), Slippage*10,
                 ArrowColor[type]);
   if (!ret)
   {
      int err = GetLastError();
      Print("MyOrderCloseParts : ", err, " ",
            ErrorDescription(err));
      rtn = false;
   } else {
      // pop and push new orderId
      int newTicket = getNewTicketNumber(OrderOpenPrice(), OrderOpenTime(), type);
      if (newTicket < 0) {
         PrintFormat("MyOrderCloseParts2: [%d]  WRONG ID ", newTicket);
      }
      if (type == OP_BUY) {
         aOrderStack[LONG].pop();
         if (newTicket > 0)
            aOrderStack[LONG].push(newTicket);
      } else {
         aOrderStack[SHORT].pop();
         if (newTicket > 0)
            aOrderStack[SHORT].push(newTicket);
      }
   }
   return(rtn);
}
// get order lots
double MyOrderLots2(int orderId)
{
   double lots = 0;

   if (orderId > 0 && OrderSelect(orderId, SELECT_BY_TICKET))
      lots = OrderLots();

   return(lots);   
}
//+------------------------------------------------------------------+
//| get order type                                                   |
//+------------------------------------------------------------------+
int MyOrderType2(int orderId)
{
   int type = OP_NONE;

   if (orderId > 0 && OrderSelect(orderId, SELECT_BY_TICKET))
      type = OrderType();

   return(type);
}

//+------------------------------------------------------------------+
//| get signed lots of open position                                 |
//+------------------------------------------------------------------+
double MyOrderOpenLots2(int orderId)
{
   int type = MyOrderType2(orderId);
   double l = 0;

   if (type == OP_BUY)  l =  OrderLots();
   if (type == OP_SELL) l = -OrderLots();

   return(l);
}
