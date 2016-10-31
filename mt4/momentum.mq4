// momentum.mq4
#property copyright "Copyright (c) 2016, aabbccddee"
#property link      "http://aabbccddee.com/"

// マイライブラリー
#define POSITIONS 2
#include <MyPosition.mqh>

// マジックナンバー
int Magic = 20161031;
string EAname[POSITIONS] = {"BBUP", "BBDN"};

// 外部パラメータ
extern double Lots = 0.1;  // 売買ロット数

// テクニカル指標の設定
#define MaxBars 3
double BB_U1[MaxBars], BB_L1[MaxBars];
double BB_U2[MaxBars], BB_L2[MaxBars];

extern int BBPeriod = 20;  // ボリンジャーバンドの期間

extern int BBDev1 = 1;      // 標準偏差の倍率
extern int BBDev2 = 2;      // 標準偏差の倍率

// テクニカル指標の更新
void RefreshIndicators() {
   for (int i = 0; i < MaxBars; i++) {
      BB_U1[i] = iBands(NULL, 0, BBPeriod, BBDev1, 0, PRICE_CLOSE, MODE_UPPER, i);
      BB_L1[i] = iBands(NULL, 0, BBPeriod, BBDev1, 0, PRICE_CLOSE, MODE_LOWER, i);

      BB_U2[i] = iBands(NULL, 0, BBPeriod, BBDev2, 0, PRICE_CLOSE, MODE_UPPER, i);
      BB_L2[i] = iBands(NULL, 0, BBPeriod, BBDev2, 0, PRICE_CLOSE, MODE_LOWER, i);
   }
}

// 終値が指標を上抜け
bool CrossUpClose(double& ind2[], int shift)
{
   return(Close[shift+1] <= ind2[shift+1] && Close[shift] > ind2[shift]);
}

// 終値が指標を下抜け
bool CrossDownClose(double& ind2[], int shift)
{
   return(Close[shift+1] >= ind2[shift+1] && Close[shift] < ind2[shift]);
}

// エントリー関数
int EntrySignal(int pos_id) {
   // オープンポジションの計算
   double pos = MyOrderOpenLots(pos_id);

   int ret = 0;
   switch(pos_id) {
      case 0:  // システム０
         // 買いシグナル
         if (pos == 0 && CrossUpClose(BB_U1, 1)) ret = 1;
         // 売りシグナル
         if (pos > 0 && CrossUpClose(BB_U2, 1)) ret = -1;
         break;

      case 1:  // システム１
         // 買いシグナル
         if (pos < 0 && CrossDownClose(BB_L2, 1)) ret = 1;
         // 売りシグナル
         if (pos == 0 && CrossDownClose(BB_L1, 1)) ret = -1;
         break;
   }
   return(ret);
}

// 初期化関数
int init() {
   // ポジションの初期化
   MyInitPosition(Magic);
   return(0);
}

// ティック時実行関数
int start() {
   // テクニカル指標の更新
   RefreshIndicators();

   // ポジションの更新
   MyCheckPosition();

   for (int i = 0; i < POSITIONS; i++) {
      // エントリーシグナル
      int sig_entry = EntrySignal(i);

      // 買い注文
      if (sig_entry > 0) {
         MyOrderClose(i);
         MyOrderSend(i, OP_BUY, Lots, 0, 0, 0, EAname[i]);
      }

      // 売り注文
      if (sig_entry < 0) {
         MyOrderClose(i);
         MyOrderSend(i, OP_SELL, Lots, 0, 0, 0, EAname[i]);
      }
   }
   return(0);
}
