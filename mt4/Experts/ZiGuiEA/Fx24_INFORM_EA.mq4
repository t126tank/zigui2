// Fx24_INFORM_EA.mq4
#property copyright "Copyright (c) 2017, Katokunou FX"
#property link      "http://katokunou.com/"

#include <ZiGuiLib\Fx24.mqh>
#include <Arrays\List.mqh>

// テクニカル指標
// https://docs.mql4.com/constants/chartconstants/enum_timeframes
input int PERIOD_FX24 = PERIOD_W1;

CList *fx24PairList;

// 初期化関数
int init()
{
   fx24PairList = new CList();
   initFx24PairList();
   return(0);
}

void deinit() {
   if (fx24PairList.GetLastNode() != NULL) {
      while (fx24PairList.DeleteCurrent())
         ;
   }
   delete fx24PairList;
}

// ティック時実行関数
int start()
{
   Fx24 *fx24;
   string subject = TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   string text = "";
   const string cl = "\n"; // change-line
   bool smFlg = false;

   for (fx24 = fx24PairList.GetFirstNode(); fx24 != NULL; fx24 = fx24PairList.GetNextNode()) {
      // RefreshIndicators
      fx24.refreshIndicators();

      // Fx24 pair inform signal
      if (fx24.isInform()) {
         text += fx24.getInformText();
         text += cl;
         smFlg = true;
      }
   }

   if (smFlg) SendMail(subject, text);

   return(0);
}

void initFx24PairList() {
   for (int i = USDJPY; i < SYM_LAST; i++) {
      Fx24 *fx24 = new Fx24(Fx24SymStr[i], PERIOD_FX24);
      fx24PairList.Add(fx24);
   }
}
