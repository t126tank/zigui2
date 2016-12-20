// RakutenSym.mqh   Version 0.01

#ifndef RAKUTENSYM_MQH
#define RAKUTENSYM_MQH

#ifdef RAKUTENSYM_MQH
enum RakutenSym {
    GBPUSD = 0,
    EURUSD,
    AUDUSD,
    SYM_LAST
};

const string RakutenSymStr[SYM_LAST] = {
    "GBPUSD", "EURUSD", "AUDUSD"
};

#else

enum RakutenSym {
    GBPUSD,
    EURUSD,
    AUDUSD,
    NZDUSD,
    AUDJPY,
    CADJPY,
    CHFJPY,
    EURJPY,
    GBPJPY,
    NZDJPY,
    TRYJPY,
    USDJPY,
    ZARJPY,
    AUDCHF,
    EURCHF,
    GBPCHF,
    NZDCHF,
    USDCHF,
    AUDNZD,
    EURGBP,
    SYM_LAST
};

string RakutenSymStr[SYM_LAST] = {
    "GBPUSD", "EURUSD", "AUDUSD", "NZDUSD", "AUDJPY",
    "CADJPY", "CHFJPY", "EURJPY", "GBPJPY", "NZDJPY",
    "TRYJPY", "USDJPY", "ZARJPY", "AUDCHF", "EURCHF",
    "GBPCHF", "NZDCHF", "USDCHF", "AUDNZD", "EURGBP"
};
#endif

#endif // RAKUTENSYM_MQH

