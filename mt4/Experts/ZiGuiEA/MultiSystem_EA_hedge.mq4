// MultiSystem_EA_hedge.mq4
#property copyright "Copyright (c) 2016, aabbccdd"
#property link      "http://aabbccdd.com/"


#define POSITIONS    (3*2)     // hedge pair positions * 2

#include <ZiGuiLib\MyPosition.mqh>
#include <ZiGuiLib\ZiGuiHedge.mqh>

#include <Arrays\List.mqh>

#include <ZiGuiLib\http\mq4-http.mqh>
#include <ZiGuiLib\http\hash.mqh>
#include <ZiGuiLib\http\json.mqh>

extern string hostIp = "katokunou.com";
extern int hostPort = 80;

MqlNet INet;

int Magic = 20161223;

CList hedgePairList;

int init()
{
   initHedgePairList();
   MyInitPosition2(Magic);
   return(0);
}

void deinit() {
   if (hedgePairList.GetLastNode() != NULL) {
      while (hedgePairList.DeleteCurrent())
         ;
   }
}

int start()
{
   ZiGuiHedge *data;
   for (data = hedgePairList.GetFirstNode(); data != NULL; data = hedgePairList.GetNextNode()) {
      // RefreshIndicators
      data.refreshIndicators();

      // MyCheckPosition
      MyCheckPosition2();

      // Hedge pair trade
      data.trade();
   }


#ifdef abcde
   RefreshIndicators();
   
   MyCheckPosition();
   
   int sig_entry = EntrySignal();
   bool deal = false;

   // Open Signals
   if (sig_entry > 0) {
   int s = 2-sig_entry;
   int b = sig_entry-1;
//      while (!deal) {
         deal = MyOrderSend2(b, EAname[b], OP_BUY, Lots, 0, 0, 0, EAname[b]);
//      }

      deal = false;
//      while (!deal) {
        deal =  MyOrderSend2(s, EAname[s], OP_SELL, Lots, 0, 0, 0, EAname[s]);
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
   return(0);

   for (int i = 0; i < POSITIONS; i++) {
      int sig_entry = EntrySignal(i);


      // json order init
      int ticket = -1;
      string op = "sell";  // "buy"
      double price = 0.0;
      string type = "close";  // "open"
      double lots = 0.1;
      datetime ctime;
      datetime otime;
      double profits = 0.0;
      bool req = false;

      if (sig_entry > 0)
      {
         // Judge if Order is Open
         if (MyOrderOpenLots(i) != 0) {
            ticket = MyPos[i];
            op = "sell";
            type = "close";
            lots = MyOrderOpenLots(i);
            req = true;
         }

         MyOrderClose(i);

         // Fetch Close order info
         if (req) {
            if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
               ctime = OrderCloseTime();
               profits = OrderProfit();
               price = OrderClosePrice();
            } else
               Print("OrderSelect failed error code is", GetLastError());

            // Send close order op
            make_request(ctime, ticket, op, price, type, lots, profits);
            req = false;
         }
 
         MyOrderSend(i, OP_BUY, Lots, 0, 0, 0, EAname[i]);

         //  Judge if Order is Open
         if (MyOrderOpenLots(i) != 0) {
            ticket = MyPos[i];
            op = "buy";
            price = OrderOpenPrice();
            type = "open";
            lots = MyOrderOpenLots(i);
            otime = OrderOpenTime();
            profits = OrderProfit();
            make_request(otime, ticket, op, price, type, lots, profits);
         }
      }

      if (sig_entry < 0)
      {
         // Judge if Order is Open
         if (MyOrderOpenLots(i) != 0) {
            ticket = MyPos[i];
            op = "buy";
            type = "close";
            lots = MyOrderOpenLots(i);
            req = true;
         }

         MyOrderClose(i);

         // Fetch Close order info
         if (req) {
            if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
               ctime = OrderCloseTime();
               profits = OrderProfit();
               price = OrderClosePrice();
            } else
               Print("OrderSelect failed error code is", GetLastError());

            // Send close order op
            make_request(ctime, ticket, op, price, type, lots, profits);
            req = false;
         }

         MyOrderSend(i, OP_SELL, Lots, 0, 0, 0, EAname[i]);

         //  Judge if Order is Open
         if (MyOrderOpenLots(i) != 0) {
            ticket = MyPos[i];
            op = "sell";
            price = OrderOpenPrice();
            type = "open";
            lots = MyOrderOpenLots(i);
            otime = OrderOpenTime();
            profits = OrderProfit();
            make_request(otime, ticket, op, price, type, lots, profits);
         }
      }
   }
#endif
   return(0);
}

int make_request(datetime time, int ticket, string op, double price, string type, double lots,  double profits) {

   //Create the client request. This is in JSON format but you can send any string
   string request =  "{\"time\":  \""
            + TimeToStr(time) + "\","
            + " \"ticket\": \""
            + IntegerToString(ticket) + "\","
            + " \"op\": \""
            + op + "\","
            + " \"price\": \""
            + DoubleToStr(price, Digits) + "\","
            + " \"symbol\": \""
            + Symbol() + "\","
            + " \"type\": \""
            + type + "\","
            + " \"lots\": \""
            + DoubleToStr(lots, Digits) + "\","
            + " \"profits\": \""
            + DoubleToStr(profits, Digits) + "\"}";

   //Create the response string
   string response = "";

   //Make the connection
   if (!INet.Open(hostIp, hostPort)) return(-1);

   if (!INet.RequestJson("POST", "/ifis/mt4/poor-post.php", response, false, true, request, false)) {
      // printDebug("-Err download ");
      return(-1);
   }
   // Print(request);
   return(0);
}

void initHedgePairList() {
   int idx = 0;

   for (int i = GBPUSD; i < SYM_LAST - 1; i++) {
      for (int j = i + 1; j < SYM_LAST; j++) {
         // Init ZiGuiHedge object
         ZiGuiHedge *zgh = new ZiGuiHedge(RakutenSymStr[i], RakutenSymStr[j]);

         // Parameters to be optimized for each
         ZiGuiHedgePara zghp;
         zghp.RShort = 16;       // Correlation Short period
         zghp.RLong  = 20;       // Correlation Long  period
         zghp.RThreshold = 0.25; // Correlation threshold (-80, +80)
         zghp.RIndicatorN = 0.1; // reserved 
         zghp.Entry = 0.1;       // Ex: Momentum abs(diff) > +80 or < -80 - OPEN
         zghp.TIndicatorN = 14;  // Ex: Trade indicator period - 14
         zghp.TakeProfits = 300; // StopLoss?
         zghp.Step  = 100;       // Trailing Stop step width
         zghp.Exit = 0.01;       // Ex: Momentum abs(diff) < +30 or > -30 - CLOSE

         zghp.RPeriod = PERIOD_D1;
         zghp.TPeriod = PERIOD_M5;

         // Set hedge parameters
         zgh.setZiGuiHedgePara(zghp);

         // Set hedge pair index
         zgh.setIndex(idx++);

         // Set hedge pair Lots
         // TODO: lots balance ...
         zgh.setLots(0.1);

         hedgePairList.Add(zgh);
      }
   }
}

void MyInitPosition2(int magic)
{
   // retrieve positions
   for (int i = 0; i < POSITIONS; i++)
   {
      int hedgeIdx = i / 2;
      ZiGuiHedge *data = hedgePairList.GetNodeAtIndex(hedgeIdx);

      int pairIdx = i % 2;

      // pips adjustment marketinfo
      int d = (int) MarketInfo(data.zgp[pairIdx].sym, MODE_DIGITS);
      double slippage = 0; // customized slip-page
      double pipPoint = MarketInfo(data.zgp[pairIdx].sym, MODE_POINT);

      if (d == 3 || d == 5)
      {
         slippage *= 10;
         pipPoint *= 10;
      }

      data.zgp[pairIdx].magic_b = magic+i;
      data.zgp[pairIdx].slOrd = 0;
      data.zgp[pairIdx].tpOrd = 0;
      data.zgp[pairIdx].slippagePips = slippage;
      data.zgp[pairIdx].pipPoint = pipPoint;

      MAGIC_B[i] = magic+i;
      MyPos[i] = 0;
      SLorder[i] = 0;
      TPorder[i] = 0;

      for (int k = 0; k < OrdersTotal(); k++)
      {
         if (OrderSelect(k, SELECT_BY_POS) == false) break;

         if (OrderSymbol() == data.zgp[pairIdx].sym &&
             OrderMagicNumber() == data.zgp[pairIdx].magic_b)
         {
            data.zgp[pairIdx].pos = OrderTicket();
            break;
         }
      }
   }
}

// check MyPosition to be called in start()
void MyCheckPosition2()
{
   for (int i = 0; i < POSITIONS; i++)
   {
      int hedgeIdx = i / 2;
      ZiGuiHedge *data = hedgePairList.GetNodeAtIndex(hedgeIdx);

      int pairIdx = i % 2;

      int pos = 0;
      for (int k = 0; k < OrdersTotal(); k++)
      { 
         if (OrderSelect(k, SELECT_BY_POS) == false) break;

         if (OrderTicket() == data.zgp[pairIdx].pos)
         {
            pos = data.zgp[pairIdx].pos;
            break;
         }
      }
      if (pos > 0)
      {
         // send SL and TP orders
         if ((data.zgp[pairIdx].slOrd > 0 || data.zgp[pairIdx].tpOrd > 0) &&
             MyOrderModify(i, 0, data.zgp[pairIdx].slOrd, data.zgp[pairIdx].tpOrd))
         {
            data.zgp[pairIdx].slOrd = 0;
            data.zgp[pairIdx].tpOrd = 0;
         }
      }
      else data.zgp[pairIdx].pos = 0;
   }
}
