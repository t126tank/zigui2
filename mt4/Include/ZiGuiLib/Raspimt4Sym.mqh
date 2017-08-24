// Raspimt4Sym.mqh   Version 0.01

#ifndef RASPIMT4SYM_MQH
#define RASPIMT4SYM_MQH

#ifdef RASPIMT4SYM_MQH
enum Raspimt4Sym {
    USDJPY = 0,
    SYM_LAST
};

const string Raspimt4SymStr[SYM_LAST] = {
    "USDJPY"
};

#else

enum Raspimt4Sym {
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

string Raspimt4SymStr[SYM_LAST] = {
    "GBPUSD", "EURUSD", "AUDUSD", "NZDUSD", "AUDJPY",
    "CADJPY", "CHFJPY", "EURJPY", "GBPJPY", "NZDJPY",
    "TRYJPY", "USDJPY", "ZARJPY", "AUDCHF", "EURCHF",
    "GBPCHF", "NZDCHF", "USDCHF", "AUDNZD", "EURGBP"
};
#endif

#endif // RASPIMT4SYM_MQH

