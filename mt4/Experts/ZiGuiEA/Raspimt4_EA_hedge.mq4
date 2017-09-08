// Raspimt4_EA_hedge.mq4
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "http://katokunou.com/"

#include <ZiGuiLib\Raspimt4Sym.mqh>
#include <ZiGuiLib\PositionMgr.mqh>
#include <ZiGuiLib\Utility.mqh>

// http://www.bk.mufg.jp/gdocs/kinri/list_j/kinri/kawase.html
input double MidRate    = 109.381;
input double TradeVol   = 3.33;
// 0.0015 = 0.01 lots * 0.5 delta / 3.33 TradeVol > spread?
input double ThresholdDelta = 0.0018;
input double ScaleCDF   = 0.03;

#include <ZiGuiLib\PositionMgr.mqh>
#define POSITIONS    (1 * 2)  // hedge pair positions * 2
#include <ZiGuiLib\MyPosition.mqh>
#include <ZiGuiLib\HedgeRequest.mqh>

#define REFRESH   (3 * 60 * 60) // 3H
int Magic = 20170822;

PositionMgr* pMgr;
Utility*     utility;
datetime initTime;

int init()
{
   initTime = TimeCurrent();
   utility = new Utility();
   pMgr = new PositionMgr(Raspimt4SymStr[USDJPY], MidRate, TradeVol, ThresholdDelta);

   string sym = pMgr.getSym();
   double currentMidRate = utility.calMidRate(MarketInfo(sym, MODE_BID), MarketInfo(sym, MODE_ASK));
   pMgr.setMidRate(MidRate); // update MidRate for debug

   // NEED to rebuild LONG/SHORT trading stacks
   MyInitPosition2();
   return(0);
}

void deinit()
{
   // If we rebuilt stacks, unnecessary to close all opening orders

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
         while (!MyOrderSend2(orderStack, OP_BUY,  tradeAmount[LONG], 0, 0, 0,  "LONG"))
            ;
         while (!MyOrderSend2(orderStack, OP_SELL, tradeAmount[SHORT], 0, 0, 0, "SHORT"))
            ;
      } else { // On hedging
         double lots;
         bool closeFlg = false;
         // close LONG  / open SHORT for (tradeAmount[LONG] < 0)
         bool closeLongFlg = tradeAmount[LONG] < 0;
         double remaining = (closeLongFlg)? -tradeAmount[LONG]: -tradeAmount[SHORT];
         double totalClz = remaining;

         while (remaining > 0) {
            orderId = (closeLongFlg)? orderStack[LONG].peek(): orderStack[SHORT].peek();
            lots = MyOrderLots2(orderId);

            double parts = remaining;
            if (lots <= remaining) {
               parts = -1;
            }
            closeFlg = MyOrderClose2(orderStack, orderId, parts, false);
            if (closeFlg && parts < 0)
               remaining -= lots;
            else if (closeFlg && parts > 0)
               remaining = 0;
            else
               break;
         }

         // To avoid slipper
         if (closeFlg) {
            if (closeLongFlg) { // close LONG  / open SHORT
               while (!MyOrderSend2(orderStack, OP_SELL, tradeAmount[SHORT], 0, 0, 0, "SHORT"))
                  ;
            } else {
               while (!MyOrderSend2(orderStack, OP_BUY,  tradeAmount[LONG],  0, 0, 0, "LONG"))
                  ;
            }
         } else {
            // Maybe just parts of close amount successful
            double partsClz = totalClz - remaining;
            if (partsClz > 0) {   // Parts close failed
               if (closeLongFlg) { // close LONG  / open SHORT
                  while (!MyOrderSend2(orderStack, OP_SELL, partsClz, 0, 0, 0, "SHORT"))
                     ;
               } else {
                  while (!MyOrderSend2(orderStack, OP_BUY,  partsClz,  0, 0, 0, "LONG"))
                     ;
               }
            }

            // For closeOrder failing recover
            pMgr.setPreTradedDelta(pMgr.getBackupPreStradedDelta());
         }
      }

      // TODO: debug
      orderStack[LONG].display();
      orderStack[SHORT].display();

      // Restart NEW Epoch
      if (orderStack[LONG].empty() || orderStack[SHORT].empty()) {
         restartEpoch();
      }
   }

   delete tmp;

   return(0);
}

void closeAllOrders() {
      OrderStack* orderStack[PositionType_ALL];
      pMgr.getOrderStack(orderStack);

      while (!orderStack[LONG].empty())
         MyOrderClose2(orderStack, orderStack[LONG].peek(),  -1, true); // whole

      while (!orderStack[SHORT].empty())
         MyOrderClose2(orderStack, orderStack[SHORT].peek(), -1, true); // whole
}

void restartEpoch() {
   closeAllOrders();

   string sym = pMgr.getSym();
   double currentMidRate = utility.calMidRate(MarketInfo(sym, MODE_BID), MarketInfo(sym, MODE_ASK));

   delete pMgr;

   // TODO: use offical mid rate
   pMgr = new PositionMgr(sym, currentMidRate, TradeVol, ThresholdDelta);

initTime = TimeCurrent();
Print(" NEW Epoch time is " + TimeToStr(initTime, TIME_DATE | TIME_SECONDS) + " @ " + currentMidRate);
}

HedgeRequest* getHedgeRequest() {
   bool tradeFlg = false;
   string sym = pMgr.getSym();
   double currentMidRate = utility.calMidRate(MarketInfo(sym, MODE_BID), MarketInfo(sym, MODE_ASK));
   double currentDelta = utility.calCurrentDelta(pMgr.getMidRate(), currentMidRate, ScaleCDF); // SHORT
   double curLongDelta = 1 - currentDelta;

   double tradeAmount[PositionType_ALL];
   tradeAmount[SHORT] = utility.calInitTradeAmount(currentDelta, pMgr.getTradeVol());
   tradeAmount[LONG]  = utility.calInitTradeAmount(curLongDelta, pMgr.getTradeVol());

   // TODO: FIRST TRADING for OPENNING BOTH
   double preStradedDelta = pMgr.getPreTradedDelta(); // SHORT
   if (preStradedDelta < 0) {
      // assume traded delta is in (0, 1)

PrintFormat("Init: [%f]  %s", currentDelta, "SHORT");
PrintFormat("Init: [%f]  %s", curLongDelta, "LONG");

      tradeFlg = true;
   } else {
      // TODO: what type is currentDelta for SHORT?
      if (fabs(currentDelta - preStradedDelta) >= fabs(pMgr.getThresholdDelta())) {
         tradeAmount[SHORT] = utility.calTradeAmount(currentDelta, preStradedDelta,     pMgr.getTradeVol());
         tradeAmount[LONG]  = -tradeAmount[SHORT];

         // TODO: debug
         tradeAmount[SHORT] = NormalizeDouble(fabs(tradeAmount[SHORT]) < 0.01? 
                              tradeAmount[SHORT] < 0? -0.01: 0.01
                              : tradeAmount[SHORT], 2);
         tradeAmount[LONG] = NormalizeDouble(fabs(tradeAmount[LONG]) < 0.01?
                              tradeAmount[LONG] < 0? -0.01: 0.01
                              : tradeAmount[LONG], 2);
PrintFormat("Trade: [%f]  %s", currentDelta - preStradedDelta, "diff delta");
PrintFormat("Slot: [%f]  %s", tradeAmount[SHORT], "SHORT");
PrintFormat("Slot: [%f]  %s", tradeAmount[LONG],  "LONG");

         bool isDay = false;
         if (Hour() >= 1 && Hour() < 23)
            isDay = true;
         tradeFlg = true; // && isDay;
      }
   }
   if (tradeFlg) {
      // For closeOrder failing recover
      pMgr.setBackupPreStradedDelta(preStradedDelta);
      pMgr.setPreTradedDelta(currentDelta);
   }

   // Check if spread floating out of range for USDJPY
   if (tradeFlg)
      tradeFlg = chkSpreadRange();

   return new HedgeRequest(tradeFlg, tradeAmount);
}

bool chkSpreadRange()
{
   int spread = MarketInfo(pMgr.getSym(), MODE_SPREAD);
   PrintFormat("[%d] in %s: OK", spread, "chkSpreadRange");
   return spread < 6;
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

   comment = DoubleToStr(pMgr.getPreTradedDelta(), 5);

   int ret = -1;
   // We doesn't care about slipper during OPEN, but need to secure OPEN
   // Maybe 10 is not enough
   if (chkSpreadRange())   // TODO: avoid spread floating
      ret = OrderSend(pMgr.getSym(), type, lots, price,
                   0, 0, 0, comment,
                   Magic, 0, ArrowColor[type]); // TODO: handle magic

// debug PrintFormat("NEW Order Id: [%d]", ret);
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
// debug          PrintFormat("Long stack peek: [%d]", aOrderStack[LONG].peek());
      } else {
         aOrderStack[SHORT].push(ret);
// debug          PrintFormat("Short stack peek: [%d]", aOrderStack[SHORT].peek());
      }
   }
   // send SL and TP orders
   // if(sl > 0) SLorder[pos_id] = sl;
   // if(tp > 0) TPorder[pos_id] = tp;

   return(rtn);
}

// flg: even loss forcily close - true
bool MyOrderClose2(OrderStack*& aOrderStack[], int orderId, double aParts, bool flg)
{
   return (aParts < 0)?
          MyOrderCloseWhole2(aOrderStack, orderId, flg):
          MyOrderCloseParts2(aOrderStack, orderId, aParts);
}

// send close order wholy
bool MyOrderCloseWhole2(OrderStack*& aOrderStack[], int orderId, bool flg)
{
   bool ret = false;
   if (MyOrderOpenLots2(orderId) == 0)
      return ret;

   // for open position
   int type = MyOrderType2(orderId);

PrintFormat("MyOrderCloseWhole2: [%d]", orderId);
   RefreshRates();
   /*
   if (((type == OP_BUY)  && (OrderClosePrice() > OrderOpenPrice())) ||
       ((type == OP_SELL) && (OrderClosePrice() < OrderOpenPrice())) ||
         flg)
   */
   if (chkSpreadRange())
      ret = OrderClose(orderId, OrderLots(),
                    OrderClosePrice(), 0,
                    ArrowColor[type]);

   if (!ret)
   {
      int err = GetLastError();
      Print("MyOrderCloseWhole2 : ", err, " ",
            ErrorDescription(err));
   } else {
      // pop open orderId
      if (type == OP_BUY) {
         aOrderStack[LONG].pop();
      } else {
         aOrderStack[SHORT].pop();
      }
   }
   return ret;
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
   bool ret = false;
   if (MyOrderOpenLots2(orderId) == 0)
      return(ret);

   // for open position
   int type = MyOrderType2(orderId);

PrintFormat("MyOrderCloseParts2: [%d] (%f -- %f)", orderId, MyOrderLots2(orderId), parts);
   RefreshRates();
   /*
   if (((type == OP_BUY)  && (OrderClosePrice() > OrderOpenPrice())) ||
       ((type == OP_SELL) && (OrderClosePrice() < OrderOpenPrice())))
   */
   if (chkSpreadRange())
      ret = OrderClose(orderId, parts,
                    OrderClosePrice(), 0,
                    ArrowColor[type]);
   if (!ret)
   {
      int err = GetLastError();
      Print("MyOrderCloseParts2 : ", err, " ",
            ErrorDescription(err));
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
   return(ret);
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


//+------------------------------------------------------------------+
//| rebuild L/S trading stacks                                       |
//+------------------------------------------------------------------+
void MyInitPosition2()
{
   OrderStack* orderStack[PositionType_ALL];
   pMgr.getOrderStack(orderStack);

   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderMagicNumber() == Magic) {
            if (OrderType() == OP_BUY)
               orderStack[LONG].push(OrderTicket());
            else
               orderStack[SHORT].push(OrderTicket());
         }
      }
   }
   // Rebuild failed
   if (orderStack[LONG].empty() || orderStack[SHORT].empty()) {
      while (!orderStack[LONG].empty())
         MyOrderClose2(orderStack, orderStack[LONG].peek(),  -1, true); // whole

      while (!orderStack[SHORT].empty())
         MyOrderClose2(orderStack, orderStack[SHORT].peek(), -1, true); // whole
   } else {
      double preTradedDelta = StrToDouble(OrderComment()); // use latest in above for {}
      pMgr.setPreTradedDelta(preTradedDelta);
      pMgr.setBackupPreStradedDelta(preTradedDelta); // TODO

      // TODO: debug
      orderStack[LONG].display();
      orderStack[SHORT].display();
      PrintFormat("Rebuild stacks: [%f]  Pre-traded-delta ", preTradedDelta);
   }
}
