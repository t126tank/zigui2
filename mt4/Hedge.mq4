// Hedge.mq4
#property copyright "Copyright (c) 2016, aabbccddee"
#property link      "http://aabbccddee.com/"

// プリプロセッサ命令（プログラム全体の設定）
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Red
#property indicator_level1 0


// 指標バッファ用の配列の宣言
double BufCorrel[];  // 相関度

double times; // Sharpe-ratio scale times
double GbpJpy[], EurJpy[], EurGbp[];

int   cnt1, cnt2, temp0, temp1 = 0;

// 外部パラメータ
extern int Q = 1;
extern int Num = 50;
extern int line_centre = 800;

// 初期化関数
int init() {
   // 使用する指標バッファの数
   IndicatorBuffers(1);

   // 指標バッファの割り当て
   SetIndexBuffer(0, BufCorrel);

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
   }   //
   if (line_centre >= temp0) {
       Comment("Wrong line centre.... ");
       return(0);
   }

   if (temp0 - line_centre < Bars - counted_bars)
       temp1 = temp0 - line_centre;
   else  
       temp1 = Bars - counted_bars;
 
   // カスタム指標の計算  
   for (int i = temp1 - 1; i >= 0; i--) {
      double gbpDiff[50];
      double eurDiff[50];
      for (int j = 0; j < Num; j++) {
         gbpDiff[j] = (GbpJpy[i + j * Q] - GbpJpy[i + (j+1) * Q])*EurGbp[j];
         eurDiff[j] = EurJpy[i + j * Q] - EurJpy[i + (j+1) * Q];
      }
      BufCorrel[i] = correl(gbpDiff, eurDiff);
   }
   return(0);
}

// http://qiita.com/LitopsQ/items/494be412b3f96d26784b
// https://github.com/maxto/ubique/blob/master/lib/quants/annadjsharpe.js
// sr * (1 + (sk/6) * sr - ((ku - 3)/24) * Math.sqrt(sr));
double correl(double gbp[], double eur[]) {
   double GBP_Average = iMAOnArray(gbp, 0, Num, 0, MODE_SMA, 0);
   double GBP_SD      = iStdDevOnArray(gbp, 0, Num, MODE_SMA, 0, 0);
   double Sxy = 0.0;


   double EUR_Average = iMAOnArray(eur, 0, Num, 0, MODE_SMA, 0);
   double EUR_SD      = iStdDevOnArray(eur, 0, Num, MODE_SMA, 0, 0);

   for (int i; i < Num; i++) {
      Sxy += (gbp[i] - GBP_Average) * (eur[i] - EUR_Average);
   }

   return Sxy/(Num-1)/(GBP_SD * EUR_SD);
}

