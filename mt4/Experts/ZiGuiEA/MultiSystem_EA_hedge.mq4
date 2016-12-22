// MultiSystem_EA_hedge.mq4
#property copyright "Copyright (c) 2016, aabbccdd"
#property link      "http://aabbccdd.com/"


#define POSITIONS (3*2)     // hedge pair positions * 2

#include <ZiGuiLib\MyPosition.mqh>
#include <ZiGuiLib\ZiGuiHedge.mqh>

#include <ZiGuiLib\http\mq4-http.mqh>
#include <ZiGuiLib\http\hash.mqh>
#include <ZiGuiLib\http\json.mqh>

extern string hostIp = "katokunou.com";
extern int hostPort = 80;

MqlNet INet;

int Magic = 20161220;
string EAname[POSITIONS] = {
   "GBPUSD",   // RakutenSymStr[GBPUSD],
   "EURUSD"    // RakutenSymStr[EURUSD]
}; // Buy pair name


extern double Lots = 0.1;


double FastMA[MaxBars];
double SlowMA[MaxBars];
extern int FastMAPeriod = 15;
extern int SlowMAPeriod = 25;

double BB_U[MaxBars];
double BB_L[MaxBars];
extern int BBPeriod = 15;
extern int BBDev = 1;

//----
double corrThreshold = 0.11;
double openThreshold = 0.03;// 0.1568;
double closThreshold = 0.003; //0.0166;

string p1 = RakutenSymStr[GBPUSD];
string p2 = RakutenSymStr[EURUSD];

double Correlation[MaxBars];
int    nCo = 20;

double Pair1[MaxBars];
double Pair2[MaxBars];
int    nMo = 12;

CList hedgePairList;

void RefreshIndicators()
{
   for(int i=0; i<MaxBars; i++)
   {
      FastMA[i] = iMA(NULL, 0, FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
      SlowMA[i] = iMA(NULL, 0, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
      BB_U[i] = iBands(NULL, 0, BBPeriod, BBDev, 0, PRICE_CLOSE, MODE_UPPER, i);
      BB_L[i] = iBands(NULL, 0, BBPeriod, BBDev, 0, PRICE_CLOSE, MODE_LOWER, i);
      Correlation[i] = iCustom(NULL, PERIOD_D1, "ZiGuiIndicators\\Correlation", p1, p2, PERIOD_D1, nCo, 0, 0);
      Pair1[i] = iMomentum(p1, PERIOD_M5, nMo, PRICE_CLOSE, 0);
      Pair2[i] = iMomentum(p2, PERIOD_M5, nMo, PRICE_CLOSE, 0);
   }
}

bool CrossUp(double& ind1[], double& ind2[], int shift)
{
   return(ind1[shift+1] <= ind2[shift+1] && ind1[shift] > ind2[shift]);
}

bool CrossDown(double& ind1[], double& ind2[], int shift)
{
   return(ind1[shift+1] >= ind2[shift+1] && ind1[shift] < ind2[shift]);
}

bool CrossUpClose(double& ind2[], int shift)
{
   return(Close[shift+1] <= ind2[shift+1] && Close[shift] > ind2[shift]);
}

bool CrossDownClose(double& ind2[], int shift)
{
   return(Close[shift+1] >= ind2[shift+1] && Close[shift] < ind2[shift]);
}

// Instructs how to trade Pair1 or Pair2
int HedgeSignal() {
   int ret = 0; // 1: buy pair1, 2: buy pair2, 0: none

   if (MathAbs(Pair1[0] - Pair2[0]) > openThreshold) {
      if (Pair1[0] > Pair2[0])
         ret = 2;
      else
         ret = 1;
   }

   return(ret);
}

// Open Signals > 0, Close Signals < 0
int EntrySignal() {
   // Judge position op is BUY or SELL or null
   // double pos = MyOrderOpenLots(pos_id);
   int ret = 0;   // -1: close, 1: buy Pair1/sell Pair2, 2: sell Pair1/buy Pair2

   double delta = MathAbs(Pair1[0] - Pair2[0]);
   static datetime oldTime = 0;

   if (oldTime == 0)
      oldTime = Time[0];
   else if (oldTime < Time[0]) {
      oldTime = Time[0];
      SendMail("MT4 Hedge: " + oldTime,
         "delta = " + delta + ", " +
         "Pair1[0] = " + Pair1[0] + ", " +
         "Pair2[0] = " + Pair2[0] + ", " +
         "Correlation[0] = " + Correlation[0]);
   }

   if (Correlation[0] > corrThreshold && delta > openThreshold) {
      if (Pair1[0] > Pair2[0])
         ret = 2;
      else
         ret = 1;
   }

   if (delta < closThreshold) {
      ret = -1;
   }
   return(ret);
}

int init()
{
   initHedgePairList();
   MyInitPosition2(Magic);
   return(0);
}

int start()
{
   ZiGuiHedge *data;
   for (data = hedgePairList.GetFirstNode(); data != NULL; data = hedgePairList.GetNextNode()) {
      // RefreshIndicators
      data.refreshIndicators();

      // MyCheckPosition
      MyCheckPosition();

      // Hedge pair trade
      data.trade();
   }

#ifdef abcde // COMMENTED

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

   for (int i = GBPJPY; i < SYM_LAST - 1; i++) {
      for (int j = i + 1; j < SYM_LAST; j++) {
         // Init ZiGuiHedge object
         ZiGuiHedge zgh = new ZiGuiHedge(ZiGuiSym[i], ZiGuiSym[j]);

         // Parameters to be optimized for each
         ZiGuiHedgePara zghp;
         zghp.RShort = 16;       // Correlation Short period
         zghp.RLong  = 20;       // Correlation Long  period
         zghp.RThreshold = 0.25; // Correlation threshold (-80, +80)
         zghp.RIndicatorN;       // reserved 
         zghp.Entry = 0.1;       // Ex: Momentum abs(diff) > +80 or < -80 - OPEN
         zghp.TIndicatorN = 14;  // Ex: Trade indicator period - 14
         zghp.TakeProfits = 300; // StopLoss?
         zghp.Step  = 100;       // Trailing Stop step width
         zghp.Exit = 0.01;       // Ex: Momentum abs(diff) < +30 or > -30 - CLOSE

         zghp.RPeriod = PERIOD_D1;
         zghp.TPeriod = PERIOD_M5;

         // Set hedge parameters
         zgh.setZiGuiHedgePara(&zghp);

         // Set hedge pair index
         zgh.setIndex(idx);

         hedgePairList.Add(zgh);

         ZiGuiHedge[idx].idx  = idx / 2;
         ZiGuiHedge[idx].pos  = inPos;
         ZiGuiHedge[idx].lots = inLots;

      }
   }
}


void MyInitPosition2(int magic)
{
   // pips adjustment marketinfo
   if (Digits == 3 || Digits == 5)
   {
      Slippage = SlippagePips * 10;
      PipPoint = Point * 10;
   }
   else
   {
      Slippage = SlippagePips;
      PipPoint = Point;
   }

   // retrieve positions
   for (int i = 0; i < POSITIONS; i++)
   {
      int hedgeIdx = i / 2;
      ZiGuiHedge *data = hedgePairList.GetNodeAtIndex(hedgeIdx);

      int pairIdx = i % 2;
      data.zgp[Idx].magic_b = magic+i;
      data.zgp[Idx].slOrd = 0;
      data.zgp[Idx].tpOrd = 0;
      data.zgp[Idx].pipPoint = PipPoint;
      data.zgp[Idx].slippagePips = Slippage;

      MAGIC_B[i] = magic+i;
      MyPos[i] = 0;
      SLorder[i] = 0;
      TPorder[i] = 0;

      for (int k = 0; k < OrdersTotal(); k++)
      {
         if (OrderSelect(k, SELECT_BY_POS) == false) break;

         if (OrderSymbol() == data.zgp[Idx].sym &&
             OrderMagicNumber() == data.zgp[Idx].magic_b)
         {
            data.zgp[Idx].pos = OrderTicket();
            break;
         }
      }
   }
}

