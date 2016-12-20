// ZiGuiHedge.mqh   Version 0.01

#property copyright "Copyright (c) 2016, abc"
#property link      "http://aabbccc.com/"

#include <ZiGuiLib\RakutenSym.mqh>

// order type extension
#define OP_NONE -1

struct ZiGuiPos[MAX_POS] {
    struct ZiGuiHedge;
}

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

struct ZiGuiHedge {
    int idx;
    int pos;
    double lots;
    bool corrlation;    // true: positive, false: negative
    struct ZiGuiPair p1;
    struct ZiGuiPair p2;
    double times;   // Ex: ZARJPY vs USDJPY
    struct ZiGuiHedgePara para;
};
