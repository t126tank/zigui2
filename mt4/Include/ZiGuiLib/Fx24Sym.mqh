// Fx24Sym.mqh   Version 0.01

#ifndef FX24SYM_MQH
#define FX24SYM_MQH

#ifndef FX24SYM_MQH
enum Fx24Sym {
    USDJPY = 0,
    EURJPY,
    AUDJPY,
    SYM_LAST
};

const string Fx24SymStr[SYM_LAST] = {
    "USDJPY", "EURJPY", "AUDJPY"
};

#else

enum Fx24SymSym {
    USDJPY = 0,
    EURJPY,
    GBPJPY,
    AUDJPY,
    ZARJPY,
    CHFJPY,
    CADJPY,
    NZDJPY,
    AUDUSD,
    GBPUSD,
    EURUSD,
    USDCHF,
    SYM_LAST
};

string Fx24SymStr[SYM_LAST] = {
    "USDJPY", "EURJPY", "GBPJPY", "AUDJPY", "ZARJPY",
    "CHFJPY", "CADJPY", "NZDJPY", "AUDUSD", "GBPUSD",
    "EURUSD", "USDCHF"
};
#endif

#endif // FX24SYM_MQH

