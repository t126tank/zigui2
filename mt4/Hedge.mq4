// Hedge.mq4 http://www.forexfactory.com/showthread.php?t=160912
#property copyright "Copyright (c) 2016, aabbccddee"
#property link      "http://aabbccddee.com/"

// プリプロセッサ命令（プログラム全体の設定）
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Red
#property indicator_level1 0

// セカンド separate window

// 指標バッファ用の配列の宣言
double BufCorrel[];  // 相関度
double gbpDiff[];
double eurDiff[];

double times; // Sharpe-ratio scale times
double GbpJpy[], EurJpy[], EurGbp[];
double avg[];

int   cnt1, cnt2, temp0, temp1 = 0;

// 外部パラメータ
extern int Q = 1;
extern int Num = 50;
extern int line_centre = 800;
extern int Length = 10;
extern int barsCount = 400;
extern double StDv = 2.5;

// 初期化関数
int init() {
   // 使用する指標バッファの数
   IndicatorBuffers(1);

   // 指標バッファの割り当て
   SetIndexBuffer(0, BufCorrel);

   SetIndexBuffer(1, gbpDiff);
   SetIndexBuffer(2, eurDiff);

   SetIndexBuffer(3, avg);

   // Sharpe-ratio scale times
   times = (PERIOD_MN1 / (Period() * Q * Num)) * 12;
   return(0);
}

// 指標計算関数
int start() {
   int counted_bars = IndicatorCounted();
   temp0 = Bars - 1;

   //
   ArrayCopySeries(GbpJpy, MODE_CLOSE, "GBPJPY", Period());
   ArrayCopySeries(EurJpy, MODE_CLOSE, "EURJPY", Period());
   ArrayCopySeries(EurGbp, MODE_CLOSE, "EURGBP", Period());
 
   if (ArraySize(GbpJpy) < temp0 + 1) {
       temp0 = ArraySize(GbpJpy) - 1;
       Comment("GbpJpy " + Period() + " " + ArraySize(GbpJpy));
   }
   if (ArraySize(EurJpy) < temp0 + 1) {
       temp0 = ArraySize(EurJpy) - 1;
       Comment("EurJpy " + Period() + " " + ArraySize(EurJpy));
   }
   if (ArraySize(EurGbp) < temp0 + 1) {
       temp0 = ArraySize(EurGbp) - 1;
       Comment("EurGbp " + Period() + " " + ArraySize(EurGbp));
   }
   //-- 指定计算数量超出历史有效数据数量
   if (line_centre >= temp0) {
       Comment("Wrong line centre.... ");
       return(0);
   }

   if (line_centre > 0)
        temp1 = MathMin(Bars - counted_bars, temp0); // temp0 用以保证历史数据有效性
   else temp1 = Bars - counted_bars;

   // カスタム指標の計算  
   for (int i = temp1 - 1; i >= 0; i--) {
      // double gbpDiff[50];
      // double eurDiff[50];
      for (int j = 0; j < Num; j++) {
         gbpDiff[j] = (GbpJpy[i + j * Q] - GbpJpy[i + (j+1) * Q])*EurGbp[j];
         eurDiff[j] = EurJpy[i + j * Q] - EurJpy[i + (j+1) * Q];
      }
      BufCorrel[i] = correl(gbpDiff, eurDiff);
   }

   for (i = temp1 - 1; i >= 0; i--) {
       avg[i] = iMAOnArray(BufCorrel, 0, Length, 0, MODE_EMA, i);
       sDev   = iStdDevOnArray(BufCorrel, 0, Length, MODE_EMA, 0, i);  
       Upperband[i] = avg[i] + (StDv * sDev);
       Lowerband[i] = avg[i] - (StDv * sDev);
       ExtMapBuffer1[i] = BufCorrel[i];     // Uptrend   correl
       ExtMapBuffer2[i] = BufCorrel[i];     // Downtrend correl
       ExtMapBuffer3[i] = Upperband[i];     // Upperband
       ExtMapBuffer4[i] = Lowerband[i];     // Lowerband
       //----
       if (BufCorrel[i] > BufCorrel[i+1])
           ExtMapBuffer2[i] = EMPTY_VALUE;
       //----
       if (BufCorrel[i] < BufCorrel[i+1])
           ExtMapBuffer1[i] = EMPTY_VALUE;
   }
   return(0);
}

// http://qiita.com/LitopsQ/items/494be412b3f96d26784b
// https://github.com/maxto/ubique/blob/master/lib/quants/annadjsharpe.js
// sr * (1 + (sk/6) * sr - ((ku - 3)/24) * Math.sqrt(sr));
double correl(double gbp[], double eur[]) {
   double GBP_Average = iMAOnArray(gbp, 0, Num, 0, MODE_SMA, 0);
   double GBP_SD      = iStdDevOnArray(gbp, 0, Num, MODE_SMA, 0, 0);
   double Sxy = 0.0; // 协方差

   double EUR_Average = iMAOnArray(eur, 0, Num, 0, MODE_SMA, 0);
   double EUR_SD      = iStdDevOnArray(eur, 0, Num, MODE_SMA, 0, 0);

   for (int i; i < Num; i++) {
      Sxy += (gbp[i] - GBP_Average) * (eur[i] - EUR_Average);
   }
   // 当相关系数的绝对值大于2/sqrt(N)，N为样本点的数量时，我们认为线性关系是存在的
   return Sxy/(Num-1)/(GBP_SD * EUR_SD);
}
