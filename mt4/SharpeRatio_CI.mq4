// Sharpe_CI.mq4
#property copyright "Copyright (c) 2016, aabbccddee"
#property link      "http://aabbccddee.com/"

// プリプロセッサ命令（プログラム全体の設定）
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Red
#property indicator_level1 0


// 指標バッファ用の配列の宣言
double BufSharpe[];  // シャープ・レシオ
double BufMain[];    // ベースラン
double BufUpper[];   // 上位ライン
double BufLower[];   // 下位ライン


// 外部パラメータ
extern int Q = 2;
extern int Num = 10;

// 初期化関数
int init() {
   // 使用する指標バッファの数
   IndicatorBuffers(1);

   // 指標バッファの割り当て
   SetIndexBuffer(0, BufSharpe);

   return(0);
}

// 指標計算関数
int start() {
   // カスタム指標の計算
   int limit = Bars - IndicatorCounted();

   for (int i = limit - 1; i >= 0; i--) {
      double array[];
      int period;
      for (int j = 0; j < (Num * Q); j += Q) {
         array[j] = Close[j] - Close[j + Q];
      }

      period = calLen();
      BufSharpe[i] = sharpeRatio(array, len);
   }
   return(0);
}

// frequency 252: daily, 52: weekly, 12: monthly, 4: quarterly
int calLen() {
   double rnt = 0.0;

   switch (timeframe) {
   case PERIOD_M1:
      break;
   case PERIOD_M5:
      break;
   case PERIOD_M15:
      break;
   case PERIOD_M30:
      break;
   case PERIOD_H1:
      break;
   case PERIOD_H4:
      break;
   case PERIOD_D1:
      break;
   case PERIOD_W1:
      break;
   case PERIOD_MN1:
   default:
      break;
   }
}

// http://qiita.com/LitopsQ/items/494be412b3f96d26784b
double sharpeRatio(double profits[]) {
   double SumER = 0;
   int cnt = ArraySize(profits);

   for (i = 0; i < cnt; i++) {
      SumER += profits[i];
   }

   double ER_Average = SumER / cnt;
   double ER_SD = iStdDevOnArray(profits, 0, Num, 0, 0, 0);
   double SR = 1;

   if (ER_SD != 0)
      SR = ER_Average / ER_SD; // ゼロ割を回避

   return SR;
}

