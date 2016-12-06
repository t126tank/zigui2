//+------------------------------------------------------------------+
//|                                                 All_usd_pair.mq4 |
//|                                                            aaaaa |
//|                                                     www.aabbc.dd |
//+------------------------------------------------------------------+
#property copyright "aaaaa"
#property link      "www.aabbc.dd"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_color1 Brown
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Blue
#property indicator_color5 Magenta
#property indicator_color6 Tan
#property indicator_color7 CadetBlue
#property indicator_color8 DarkOrchid

extern   int line_centre = 400;  //
extern   int dir_EurUsd = 1;  // for usd
extern   int dir_GbpUsd = 1;
extern   int dir_AudUsd = 1;
extern   int dir_UsdChf = 0;  // for 1/usd
extern   int dir_UsdJpy = 0;
extern   int dir_UsdCad = 0;


int   ia, ib, ic, id, ie = 0;
int   cnt1, cnt2, temp0, temp1 = 0;
double   centre_EurUsd, centre_UsdChf, centre_GbpUsd, centre_UsdJpy; 
double   centre_AudUsd, centre_UsdCad, centre_curent;

//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];
double ExtMapBuffer6[];
double ExtMapBuffer7[];
double ExtMapBuffer8[];

double EurUsd[], UsdChf[], GbpUsd[], UsdJpy[], AudUsd[], UsdCad[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
//---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,ExtMapBuffer2);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,ExtMapBuffer3);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,ExtMapBuffer4);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexBuffer(4,ExtMapBuffer5);
   SetIndexStyle(5,DRAW_LINE);
   SetIndexBuffer(5,ExtMapBuffer6);
   SetIndexStyle(6,DRAW_LINE);
   SetIndexBuffer(6,ExtMapBuffer7);
   SetIndexStyle(7,DRAW_LINE);
   SetIndexBuffer(7,ExtMapBuffer8);
//----
   return(0);
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit() {
   ObjectDelete("EurUsd");
   ObjectDelete("GbpUsd");
   ObjectDelete("AudUsd");
   ObjectDelete("UsdChf");
   ObjectDelete("UsdJpy");
   ObjectDelete("UsdCad");  
//----
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {
   // counted_bars 首次为零； 之后为所有已经计算过的 Bar 的个数
   int counted_bars = IndicatorCounted();
//---- 
   ArrayCopySeries(EurUsd, MODE_CLOSE, "EURUSD", Period());
   ArrayCopySeries(GbpUsd, MODE_CLOSE, "GBPUSD", Period());
   ArrayCopySeries(AudUsd, MODE_CLOSE, "AUDUSD", Period());
   ArrayCopySeries(UsdChf, MODE_CLOSE, "USDCHF", Period());
   ArrayCopySeries(UsdJpy, MODE_CLOSE, "USDJPY", Period());
   ArrayCopySeries(UsdCad, MODE_CLOSE, "USDCAD", Period());

   // temp0 为 出现 Bar 的个数减一
   temp0 = Bars - 1;
   if (ArraySize(EurUsd) < temp0 + 1) {
       temp0 = ArraySize(EurUsd) - 1;
       Comment("EurUsd " + Period() + " " + ArraySize(EurUsd));
   }

   if (ArraySize(GbpUsd) < temp0 + 1) {
       temp0 = ArraySize(GbpUsd) - 1;
       Comment("GbpUsd " + Period() + " " + ArraySize(GbpUsd));
   }

   if (ArraySize(AudUsd) < temp0 + 1 ) {
       temp0 = ArraySize(AudUsd) - 1;
       Comment("AudUsd " + Period() + " " + ArraySize(AudUsd)); 
   }

   if (ArraySize(UsdChf) < temp0 + 1) {
       temp0 = ArraySize(UsdChf) - 1;
       Comment("UsdChf " + Period() + " " + ArraySize(UsdChf));
   }

   if (ArraySize(UsdJpy) < temp0 + 1) {
       temp0 = ArraySize(UsdJpy) - 1;
       Comment("UsdJpy " + Period() + " " + ArraySize(UsdJpy));
   }

   if (ArraySize(UsdCad) < temp0 + 1) {
       temp0 = ArraySize(UsdCad) - 1;
       Comment("UsdCad " + Period() + " " + ArraySize(UsdCad));
   }

   // 历史记录不足制定的参考个数
   if (line_centre >= temp0) {
       Comment("Wrong line centre.... ");
       return(0);
   }
 
   // Bars - counted_bars 首次为未计算过的Bar的个数；之后 应为 1 即 temp1
   if (temp0 - line_centre < Bars - counted_bars)
       temp1 = temp0 - line_centre;
   else  
       temp1 = Bars - counted_bars;
//----
   for (ia = temp1; ia >= 0; ia--) {
       //
       centre_EurUsd = 0;
       centre_GbpUsd = 0;
       centre_AudUsd = 0;
       centre_UsdChf = 0;
       centre_UsdJpy = 0;
       centre_UsdCad = 0;
       centre_curent = 0;

       //----
       for (ic = line_centre - 1; ic >= 0; ic--) {
           centre_EurUsd = centre_EurUsd + EurUsd[ia+ic]; 
           centre_GbpUsd = centre_GbpUsd + GbpUsd[ia+ic]; 
           centre_AudUsd = centre_AudUsd + AudUsd[ia+ic]; 
           centre_UsdChf = centre_UsdChf + UsdChf[ia+ic]; 
           centre_UsdJpy = centre_UsdJpy + UsdJpy[ia+ic]; 
           centre_UsdCad = centre_UsdCad + UsdCad[ia+ic]; 
           centre_curent = centre_curent + Close[ia+ic]; 
       }
       centre_EurUsd = centre_EurUsd / line_centre;
       centre_GbpUsd = centre_GbpUsd / line_centre;
       centre_AudUsd = centre_AudUsd / line_centre;
       centre_UsdChf = centre_UsdChf / line_centre;
       centre_UsdJpy = centre_UsdJpy / line_centre;
       centre_UsdCad = centre_UsdCad / line_centre;
       centre_curent = centre_curent / line_centre;

       //
       ExtMapBuffer1[ia] = (dir_EurUsd*EurUsd[ia] + (1 - dir_EurUsd) / 
                            EurUsd[ia])*centre_curent / (dir_EurUsd*centre_EurUsd + 
                            (1 - dir_EurUsd) / centre_EurUsd);
       ExtMapBuffer2[ia] = (dir_GbpUsd*GbpUsd[ia] + (1 - dir_GbpUsd) / 
                            GbpUsd[ia])*centre_curent / (dir_GbpUsd*centre_GbpUsd + 
                            (1 - dir_GbpUsd) / centre_GbpUsd);
       ExtMapBuffer3[ia] = (dir_AudUsd*AudUsd[ia] + (1 - dir_AudUsd) / 
                            AudUsd[ia])*centre_curent / (dir_AudUsd*centre_AudUsd + 
                            (1 - dir_AudUsd) / centre_AudUsd);
       ExtMapBuffer4[ia] = (dir_UsdChf*UsdChf[ia] + (1 - dir_UsdChf) / 
                            UsdChf[ia])*centre_curent / (dir_UsdChf*centre_UsdChf + 
                            (1 - dir_UsdChf) / centre_UsdChf);
       ExtMapBuffer5[ia] = (dir_UsdJpy*UsdJpy[ia] + (1 - dir_UsdJpy) / 
                            UsdJpy[ia])*centre_curent / (dir_UsdJpy*centre_UsdJpy + 
                            (1 - dir_UsdJpy) / centre_UsdJpy);
       ExtMapBuffer6[ia]= (dir_UsdCad*UsdCad[ia] + (1 - dir_UsdCad) / 
                           UsdCad[ia])*centre_curent / (dir_UsdCad*centre_UsdCad + 
                           (1 - dir_UsdCad) / centre_UsdCad);
       /*
       Comment("Debug: "+Period()
          +"\nGBPUSD  -"+GbpUsd[0]
          +"\nUSDJPY  -"+UsdJpy[0]
          );
       */
       if ((Bars - counted_bars) == 1) {
           //
           ObjectDelete("EurUsd");
           ObjectCreate("EurUsd", OBJ_TEXT, 0, Time[0] + Period()*11*60, ExtMapBuffer1[0]);
           ObjectSet("EurUsd", OBJPROP_COLOR, Brown);
           ObjectSetText("EurUsd", "EurUsd " + DoubleToStr(EurUsd[0], 4), 8, "arial");
           //----
           ObjectDelete("GbpUsd");
           ObjectCreate("GbpUsd", OBJ_TEXT, 0, Time[0] + Period()*11*60, ExtMapBuffer2[0]);
           ObjectSet("GbpUsd", OBJPROP_COLOR, Red);
           ObjectSetText("GbpUsd", "GbpUsd " + DoubleToStr(GbpUsd[0], 4), 8, "arial");
           //----
           ObjectDelete("AudUsd");
           ObjectCreate("AudUsd", OBJ_TEXT, 0, Time[0] + Period()*11*60, ExtMapBuffer3[0]);
           ObjectSet("AudUsd", OBJPROP_COLOR, Green);
           ObjectSetText("AudUsd", "AudUsd " + DoubleToStr(AudUsd[0], 4), 8, "arial");
           //----
           ObjectDelete("UsdChf");
           ObjectCreate("UsdChf", OBJ_TEXT, 0, Time[0] + Period()*11*60, ExtMapBuffer4[0]);
           ObjectSet("UsdChf", OBJPROP_COLOR, Blue);
           ObjectSetText("UsdChf", "UsdChf " + DoubleToStr(UsdChf[0], 4), 8, "arial");
           //----
           ObjectDelete("UsdJpy");
           ObjectCreate("UsdJpy", OBJ_TEXT, 0, Time[0] + Period()*11*60, ExtMapBuffer5[0]);
           ObjectSet("UsdJpy", OBJPROP_COLOR, Magenta);
           ObjectSetText("UsdJpy", "UsdJpy " + DoubleToStr(UsdJpy[0], 2), 8, "arial");
           //----
           ObjectDelete("UsdCad");
           ObjectCreate("UsdCad", OBJ_TEXT, 0, Time[0] + Period()*11*60, ExtMapBuffer6[0]);
           ObjectSet("UsdCad", OBJPROP_COLOR, Tan);
           ObjectSetText("UsdCad", "UsdCad " + DoubleToStr(UsdCad[0], 4), 8, "arial");
         }

   }
//----
   return(0);
}
//+------------------------------------------------------------------+
