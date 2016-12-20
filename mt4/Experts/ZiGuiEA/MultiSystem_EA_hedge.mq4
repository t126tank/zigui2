// MultiSystem_EA.mq4
#property copyright "Copyright (c) 2012, Toyolab FX"
#property link      "http://forex.toyolab.com/"


#define POSITIONS 2     // hedge pair positions
#include <ZiGuiLib\ZiGuiHedge.mqh>
#include <ZiGuiLib\MyPosition.mqh>

#include <ZiGuiLib\http\mq4-http.mqh>
#include <ZiGuiLib\http\hash.mqh>
#include <ZiGuiLib\http\json.mqh>

extern string hostIp = "katokunou.com";
extern int hostPort = 80;

MqlNet INet;


int Magic = 20161220;
string EAname[POSITIONS] = {
   RakutenSymStr[GBPUSD],
   RakutenSymStr[EURUSD]
}; // Buy pair name


extern double Lots = 0.1;

#define MaxBars 3
double FastMA[MaxBars];
double SlowMA[MaxBars];
extern int FastMAPeriod = 15;
extern int SlowMAPeriod = 25;

double BB_U[MaxBars];
double BB_L[MaxBars];
extern int BBPeriod = 15;
extern int BBDev = 1;

//----
double corrThreshold = 0.25;
double openThreshold = 10;
double closThreshold = 2;

string p1 = RakutenSymStr[GBPUSD];
string p2 = RakutenSymStr[EURUSD];

double Correlation[MaxBars];
int    nCo = 20;

double Pair1[MaxBars];
double Pair2[MaxBars];
int    nMo = 12;

void RefreshIndicators()
{
   for(int i=0; i<MaxBars; i++)
   {
      FastMA[i] = iMA(NULL, 0, FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
      SlowMA[i] = iMA(NULL, 0, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, i);
      BB_U[i] = iBands(NULL, 0, BBPeriod, BBDev, 0, PRICE_CLOSE, MODE_UPPER, i);
      BB_L[i] = iBands(NULL, 0, BBPeriod, BBDev, 0, PRICE_CLOSE, MODE_LOWER, i);
      Correlation[i] = iCustom(NULL, 0, "\\ZiGuiIndicators\Correlation", p1, p2, PERIOD_D1, nCo, 0, 0);
      Pair1[i] = iMomentum(p1, 0, nMo, PRICE_CLOSE, 0);
      Pair2[i] = iMomentum(p2, 0, nMo, PRICE_CLOSE, 0);
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

// Instructs how to trade Pair1
int HedgeSignal1() {
   int ret = 0; // 1: buy, -1: sell, 0: none

   if (abs(Pair1[0] - Pair2[0]) > openThreshold) {
      if (Pair1[0] > Pair2[0])
         ret = -1;
      else
         ret = 1;
   }

   return ret;
}

// Open Signals > 0, Close Signals < 0
int EntrySignal() {
   // Judge position op is BUY or SELL or null
   double pos = MyOrderOpenLots(pos_id);
   int ret = 0;   // -1: close, 1: buy Pair1/sell Pair2, 2: sell Pair1/buy Pair2

   if (Correlation[0] > corrThreshold) {
      if (HedgeSignal1 == 1)
         return 1;   // buy Pair1
      if (HedgeSignal1 == -1)
         return 2;   // buy Pair2
   }
 
   if (abs(Pair1[0] - Pair2[0]) > closThreshold) {
      ret = -1;
   }
   return(ret);
}

int init()
{
   MyInitPosition(Magic);
   return(0);
}

int start()
{
   RefreshIndicators();
   
   MyCheckPosition();
   
   int sig_entry = EntrySignal();
   
   // Open Signals
   if (sig_entry > 0) {

      MyOrderSend(sig_entry - 1, OP_BUY, Lots, 0, 0, 0, EAname[sig_entry - 1]);
      MyOrderSend(2 - sig_entry, OP_SELL, Lots, 0, 0, 0, EAname[2 - sig_entry]);
   }

   // Close Signals
   if (sig_entry < 0) {
      MyOrderClose(0);
      MyOrderClose(1);
   }

   return(0);

#if 0
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
   return(0);
#endif
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


