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

double times; // Sharpe-ratio scale times

// 外部パラメータ
extern int Q = 2;
extern int Num = 10;

// 初期化関数
int init() {
   // 使用する指標バッファの数
   IndicatorBuffers(1);

   // 指標バッファの割り当て
   SetIndexBuffer(0, BufSharpe);

   // Sharpe-ratio scale times
   times = (PERIOD_MN1 / (Period() * Q * Num)) * 12;
   return(0);
}

// 指標計算関数
int start() {
   // カスタム指標の計算
   int limit = Bars - IndicatorCounted();

   for (int i = limit - 1; i >= 0; i--) {
      double array[];

      for (int j = 0; j < Num; j++) {
         array[j] = Close[j * Q] - Close[(j+1) Q];
      }

      BufSharpe[i] = sharpeRatio(array) * times;
   }
   return(0);
}

// http://qiita.com/LitopsQ/items/494be412b3f96d26784b
// https://github.com/maxto/ubique/blob/master/lib/quants/annadjsharpe.js
// sr * (1 + (sk/6) * sr - ((ku - 3)/24) * Math.sqrt(sr));

// http://plusforex.blogspot.com/2012/09/bb-macd-bollinger-bands-with-moving.html
// http://ameblo.jp/meta49/entry-11128736166.html
double sharpeRatio(double profits[]) {
   double SumER = 0;
   int cnt = ArraySize(profits);

   for (i = 0; i < cnt; i++) {
      SumER += profits[i];
   }

   double ER_Average = SumER / cnt;
   double ER_SD = iStdDevOnArray(profits, 0, cnt, 0, 0, 0); // cnt?
   double SR = 1;

   if (ER_SD != 0)
      SR = ER_Average / ER_SD; // ゼロ割を回避

   return SR;
}

