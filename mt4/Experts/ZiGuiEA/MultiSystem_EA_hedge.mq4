// MultiSystem_EA_hedge.mq4
#property copyright "Copyright (c) 2016, aabbccdd"
#property link      "http://aabbccdd.com/"

#include <ZiGuiLib\RakutenSym.mqh>
#define POSITIONS    (SYM_LAST*2)     // hedge pair positions * 2

#include <ZiGuiLib\MyPosition.mqh>

#include <Arrays\List.mqh>

#include <ZiGuiLib\http\mq4-http.mqh>
#include <ZiGuiLib\http\hash.mqh>
#include <ZiGuiLib\http\json.mqh>

#include <ZiGuiLib\ZiGuiHedge.mqh>


int Magic = 20161223;

CList *hedgePairList;

int init()
{
   hedgePairList = new CList();
   initHedgePairList();
   MyInitPosition2(Magic);
   return(0);
}

void deinit() {
   if (hedgePairList.GetLastNode() != NULL) {
      while (hedgePairList.DeleteCurrent())
         ;
   }
   delete hedgePairList;
}

int start()
{
   ZiGuiHedge *hedge;

   // MyCheckPosition
   MyCheckPosition2();

   for (hedge = hedgePairList.GetFirstNode(); hedge != NULL; hedge = hedgePairList.GetNextNode()) {
      // RefreshIndicators
      hedge.refreshIndicators();

      // Hedge pair trade
      hedge.trade();
    }
   //printSummary();

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
#ifdef abcde
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
#endif
void printSummary(void)
{
    ZiGuiHedge* h;

    for (h = hedgePairList.GetFirstNode(); h != NULL; h = hedgePairList.GetNextNode()) {
      PrintFormat("[%d][0]  %s: OK", h.getIndex(), h.zgp[0].sym);
      PrintFormat("[%d][1]  %s: OK", h.getIndex(), h.zgp[1].sym);
    }
}

void initHedgePairList() {
   int idx = 0;

   for (int i = GBPUSD; i < SYM_LAST - 1; i++) {
      for (int j = i + 1; j < SYM_LAST; j++) {
         // Init ZiGuiHedge object
         ZiGuiHedge *zgh = new ZiGuiHedge(RakutenSymStr[i], RakutenSymStr[j]);

         // Parameters to be optimized for each
         ZiGuiHedgePara zghp;
         zghp.RShort = 18;       // Correlation Short period
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

/*
         Trailing Stop Details(TSFlag):
         # Init
           Assume all hedge pairs are NOT on trailing-stop -> TSFlog = false

         # Trade
           * Both hedge pairs are closed -> TSFlag = false (Set in MyCheckPosition2())
           * Half hedge pair  is  closed -> TSFlag = true
           * sig < 0 means to close hege pairs -> TSFlag = true
           * Trailing-Stop started -> TSFlag = true (Continue CLOSE by TS until Both closed)
*/
         zgh.setTSStarted(false); // Assume hedge pairs are NOT on trailing-stop

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
      int pairIdx  = i % 2;
      ZiGuiHedge *hedge = hedgePairList.GetNodeAtIndex(hedgeIdx);

      // pips adjustment marketinfo
      int d = (int) MarketInfo(hedge.zgp[pairIdx].sym, MODE_DIGITS);
      double slippage = 0; // customized slip-page
      double pipPoint = MarketInfo(hedge.zgp[pairIdx].sym, MODE_POINT);

      if (d == 3 || d == 5)
      {
         slippage *= 10;
         pipPoint *= 10;
      }

      hedge.zgp[pairIdx].magic_b = magic+i;
      hedge.zgp[pairIdx].slOrd = 0;
      hedge.zgp[pairIdx].tpOrd = 0;
      hedge.zgp[pairIdx].slippagePips = slippage;
      hedge.zgp[pairIdx].pipPoint = pipPoint;
      hedge.zgp[pairIdx].pos = 0;

      for (int k = 0; k < OrdersTotal(); k++)
      {
         if (OrderSelect(k, SELECT_BY_POS) == false) break;

         if (OrderSymbol() == hedge.zgp[pairIdx].sym &&
             OrderMagicNumber() == hedge.zgp[pairIdx].magic_b)
         {
            hedge.zgp[pairIdx].pos = OrderTicket();
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
      int pairIdx  = i % 2;
      ZiGuiHedge *hedge = hedgePairList.GetNodeAtIndex(hedgeIdx);

      hedge.zgp[pairIdx].pos = 0;

      for (int k = 0; k < OrdersTotal(); k++)
      {
         if (OrderSelect(k, SELECT_BY_POS) == false) break;

         if (OrderSymbol() == hedge.zgp[pairIdx].sym &&
             OrderMagicNumber() == hedge.zgp[pairIdx].magic_b)
         {
            hedge.zgp[pairIdx].pos = OrderTicket();
            break;
         }
      }

#ifdef sendslandtporders
      int pos = 0;
      for (int k = 0; k < OrdersTotal(); k++)
      { 
         if (OrderSelect(k, SELECT_BY_POS) == false) break;

         if (OrderTicket() == hedge.zgp[pairIdx].pos)
         {
            pos = hedge.zgp[pairIdx].pos;
            break;
         }
      }
      if (pos > 0)
      {
         // send SL and TP orders
         if ((hedge.zgp[pairIdx].slOrd > 0 || hedge.zgp[pairIdx].tpOrd > 0) &&
             MyOrderModify(i, 0, hedge.zgp[pairIdx].slOrd, hedge.zgp[pairIdx].tpOrd))
         {
            hedge.zgp[pairIdx].slOrd = 0;
            hedge.zgp[pairIdx].tpOrd = 0;
         }
      }
      else hedge.zgp[pairIdx].pos = 0;
#endif
   }
}
