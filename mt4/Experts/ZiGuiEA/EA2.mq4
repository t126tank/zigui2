// glt_simple_EA2.mq4
#property copyright "Copyright 2018, Katokunou Corp."
#property link      "http://katokunou.com/"

// input
input double Highest = 120.555;
input double SHigh = 115.666;
input double BLow  = 105.666;
input double Lowest  = 100.555;

input int Max = 10;
input double Profit = 0.055;
input double Space = 0.041;
input double Lots = 0.01;

// definition
#define FACTOR(op)  (op == OP_BUY? 1: -1)
#define ARRAY_MAX 1000
#define PAIR 2

// data structures
struct PARAM {
    int max;
    double limit1;
    double limit2;
};

struct OrdOpen {
    int ordId;
    double openPrice;  /* ソートするキーの型 */
};

struct OrdOpenInfo {
    OrdOpen ordOpen[PAIR][ARRAY_MAX];
    int openLen[PAIR];
};

// global variables
OrdOpenInfo ordOpenInfo;
PARAM params[PAIR];
const int Magic = 20181107;
const string Sym = "USDJPY";
const color ArrowColor[PAIR] = {Blue, Red};

int init() {
    params[OP_BUY].max = Max;
    params[OP_BUY].limit2 = Highest; // highest should be gt high
    params[OP_BUY].limit1 = SHigh;

    params[OP_SELL].max = Max;
    params[OP_SELL].limit1 = BLow;
    params[OP_SELL].limit2 = Lowest; // lowest should be lt low

    return 0;
}

int start() {
    // OrdOpen arrays length initial
    ordOpenInfo.openLen[OP_BUY]  = 0;
    ordOpenInfo.openLen[OP_SELL] = 0;

    // OrdOpen arrays initial
    for (int i = 0; i < OrdersTotal(); i++)
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            if (OrderMagicNumber() == Magic) { // symbol needs checking as well
                int opType = OrderType();
                ordOpenInfo.ordOpen[opType][ordOpenInfo.openLen[opType]].ordId = OrderTicket();
                ordOpenInfo.ordOpen[opType][ordOpenInfo.openLen[opType]++].openPrice = OrderOpenPrice();
            }

    // ONLY First Time
    for (int op = OP_BUY; op <= OP_SELL; op++)
        if (ordOpenInfo.openLen[op] == 0)
            ordOpenInfo.ordOpen[op][0].openPrice = op == OP_BUY? 0: 1000;

    // Update both to send orders' max limitations
    updOrdSendMax();

    for (op = OP_BUY; op <= OP_SELL; op++) {
        int dualOp = OP_SELL - op;

        // sorting order open array: OP_SELL - ASC, OP_BUY - DESC
        OrdOpen dst[ARRAY_MAX];
        for (i = 0; i < ordOpenInfo.openLen[dualOp]; i++)
            dst[i] = ordOpenInfo.ordOpen[dualOp][i];

        quicksort(dst, 0, ordOpenInfo.openLen[dualOp] - 1, dualOp);

        for (i = 0; i < ordOpenInfo.openLen[dualOp]; i++)
            ordOpenInfo.ordOpen[dualOp][i] = dst[i];

        int sum = 0;
        int opMax = params[dualOp].max; // BUY behavior handles OrdOpenInfo.ordOpen[OP_SELL];
        double curr = currRate();
        while (TRUE) { // bu bu zu
            double price = op == OP_BUY? curr + Space*(sum+1): curr - Space*(sum+1);
            if (((price < ordOpenInfo.ordOpen[dualOp][0].openPrice && op == OP_BUY) ||
                (price > ordOpenInfo.ordOpen[dualOp][0].openPrice && op == OP_SELL)) &&
                (opMax > 0)) {
                double tp = op == OP_BUY? price + Profit: price - Profit;
                price = NormalizeDouble(price + Profit, MarketInfo(Sym, MODE_DIGITS));
                OrderSend(Sym, op, Lots, price,0,0, tp, "send", Magic, 0, ArrowColor[op]);
                sum++;
                opMax--;
            } else
                break;
        }

        while (++opMax < ordOpenInfo.openLen[dualOp])   // sun you yu
            OrderDelete(ordOpenInfo.ordOpen[dualOp][opMax-1].ordId, ArrowColor[op]);
    }
    return 0;
}

double currRate() {
    return (MarketInfo(Sym, MODE_BID) + MarketInfo(Sym, MODE_ASK)) / 2;
}

int intMax(int l, int r) {
    return l > r? l: r;
}

void updOrdSendMax() {
    for (int op = OP_BUY; op <= OP_SELL; op++) {
        int dualOp = OP_SELL - op;

        // judge range
        double curr = currRate();
        double diff1 = (curr - params[op].limit1) * FACTOR(op);
        double diff2 = (curr - params[op].limit2) * FACTOR(op);
        if (diff2 > 0) { // out of trading limitation2
            int reduce = Max - round(diff2 / Space);
            params[op].max = 0;
            params[dualOp].max = intMax(reduce, 0);
            break;
        } else if (diff1 > 0) { // out of trading limitation1
            reduce = Max - round(diff1 / Space);
            params[op].max = intMax(reduce, 0);
            params[dualOp].max = Max;
            break;
        } else {
            params[op].max = Max;
            params[dualOp].max = Max;
        }
    }
}

/* x, y, z の中間値を返す */
OrdOpen med3(OrdOpen& x, OrdOpen& y, OrdOpen& z, int op) {
   if (((x.openPrice < y.openPrice) && (op == OP_SELL)) || ((x.openPrice > y.openPrice) && (op == OP_BUY))) // ASC || DESC
      if (y.openPrice < z.openPrice) return op == OP_SELL? y: z; else if (z.openPrice < x.openPrice) return op == OP_SELL? x: z; else return z; else
      if (z.openPrice < y.openPrice) return op == OP_SELL? y: z; else if (x.openPrice < z.openPrice) return op == OP_SELL? x: z; else return z;
}

/* クイックソート
 * a     : ソートする配列
 * left  : ソートするデータの開始位置
 * right : ソートするデータの終了位置
 */
void quicksort(OrdOpen& a[], int left, int right, int op) {
   if (left < right) {
      int i = left, j = right;
      OrdOpen tmp, pivot = med3(a[i], a[i + (j - i) / 2], a[j], op); /* (i+j)/2ではオーバーフローしてしまう */
      while (TRUE) { /* a[] を pivot 以上と以下の集まりに分割する */
         if (op == OP_SELL) { // ASC
            while (a[i].openPrice < pivot.openPrice) i++; /* a[i] >= pivot となる位置を検索 */
            while (pivot.openPrice < a[j].openPrice) j--; /* a[j] <= pivot となる位置を検索 */
         } else { // DESC
            while (a[i].openPrice > pivot.openPrice) i++; /* a[i] <= pivot となる位置を検索 */
            while (pivot.openPrice > a[j].openPrice) j--; /* a[j] >= pivot となる位置を検索 */
         }
         if (i >= j) break;
         tmp = a[i]; a[i] = a[j]; a[j] = tmp; /* a[i],a[j] を交換 */
         i++; j--;
      }
      quicksort(a, left, i - 1, op);  /* 分割した左を再帰的にソート */
      quicksort(a, j + 1, right, op); /* 分割した右を再帰的にソート */
   }
}


・initial
to open long  - 98 96 94 92 90 88 86 84 82 80
current       - 100
to oepn short - 102 104 106 108 110 112 114 116 118 120


・100 up to 105
to cancel long - 84 82 80
to open long   - [103 101 99] 98 96 94 92 90 88 86
current        - 105
to close short - 102->99 104->101 ※
to oepn short  - 106 108 110 112 114 116 118 120 [122 124]


・105 dn to 97
to open long    - 96 94 92 90 88 86 [84 82 80 78]
to close long   - 103->106 101->104 99->102 98->101 ※
current         - 97
to oepn short   - [99 101 103 105] 106 108 110 112 114 116
to cancel short - 118 120 122 124
