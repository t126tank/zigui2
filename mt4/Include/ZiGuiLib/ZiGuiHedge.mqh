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
}

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
}

struct ZiGuiHedge[] {
    int idx;
    int pos;
    double lots;
    bool corrlation;    // true: positive, false: negative
    struct ZiGuiPair p1;
    struct ZiGuiPair p2;
}
