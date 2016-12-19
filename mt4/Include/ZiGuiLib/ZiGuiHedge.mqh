// ZiGuiHedge.mqh Version
#property copyright "Copyright (c) 2013, abc"
#property link      "http://aabbccc.com/"

#include <stderror.mqh>
#include <stdlib.mqh>

// order type extension
#define OP_NONE -1

struct ZiGuiPos[MAX_POS] {
    struct ZiGuiHedge;
}

enum ZiGuiSymbol {
    GBPJPY = 0,
    EURJPY,
    GBPUSD,
    EURUSD,
    ...
    SYM_LAST
};

string ZiGuiSym[SYM_LAST] = {
    "GBPJPY", "EURJPY", "GBPUSD", "EURUSD", ...
};

struct ZiGuiPair {
    string sym;
    int  pos;       // order ticket
    inr  magic_b;   // magic number of buy
    double slOrd;   // stop loss
    double tpOrd;   // take profits
    double pipPoint;    // pips adjustment
    double slippagePips;// slippage
};

struct ZiGuiHedgePara {
    int RShort; // Correlation Short period
    int RLong;  // Correlation Long period
    double Threshold;   // Correlation threshold (-80, +80)
    double RIndicatorN; // reserved 
    double Entry;       // Ex: Momentum abs(diff) > +80 or < -80 - OPEN
    double TIndicatorN; // Ex: Trade indicator period - 14
    double TakeProfits; // StopLoss?
    double Step;        // Trailing Stop step width
    double Exit;        // Ex: Momentum abs(diff) < +30 or > -30 - CLOSE
};

struct ZiGuiHedge[] {
    int idx;
    int pos;
    double lots;
    bool corrlation;    // true: positive, false: negative
    struct ZiGuiPair p1;
    struct ZiGuiPair p2;
    double times;   // Ex: ZARJPY vs USDJPY
    struct ZiGuiHedgePara para;
};
