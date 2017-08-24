//+------------------------------------------------------------------+
//|                                                         Fx24.mqh |
//|                                  Copyright 2017, Katokunou Corp. |
//|                                             http://katokunou.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Katokunou Corp."
#property link      "https://katokunou.com"
#property version   "1.00"
#property strict

#include <Object.mqh>
#include <ZiGuiLib\Fx24Sym.mqh>

#define NONE_INFORM  "X"
enum InformLvl {
    WEAK = 0,
    MID,
    STRING,
    INFORM_LVL
};
enum TradeLvl {
    SS = -3,   // strong sel
    MS = -2,
    WS = -1,
    NONE = 0,
    WB,
    MB,
    SB,
    TRADE_LVL
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Fx24 : public CObject
  {
private:
    string           sym;
    int              period;
    bool             informFlg;
    string           buy[INFORM_LVL];
    string           sell[INFORM_LVL];

    TradeLvl         macdLvl;
    TradeLvl         stochasticLvl;
    TradeLvl         cciLvl;
    TradeLvl         preMacdLvl;
    TradeLvl         preStochasticLvl;
    TradeLvl         preCciLvl;

    void             calMacdLvl();
    void             calStoLvl();
    void             calCciLvl();

public:
                     Fx24(string aSym, int aPeriod);
                    ~Fx24();
    //
    string           getInformText(void);
    //
    void             refreshIndicators(void);
    //
    bool             isInform();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Fx24::Fx24(string aSym, int aPeriod)
  {
    this.sym = aSym;
    this.period = aPeriod;

    this.informFlg = false;
    this.macdLvl = NONE;
    this.stochasticLvl = NONE;
    this.cciLvl = NONE;
    this.preMacdLvl = NONE;
    this.preStochasticLvl = NONE;
    this.preCciLvl = NONE;

    int i;
    buy[WEAK]  = "+";
    sell[WEAK] = "-";
    for (i = MID; i < INFORM_LVL; i++) {
      buy[i]  = buy[i - 1]  + "+";
      sell[i] = sell[i - 1] + "-";
    }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Fx24::~Fx24()
  {
  }
//+------------------------------------------------------------------+
//| Refresh Indicator for inform sigals                              |
//+------------------------------------------------------------------+
void Fx24::refreshIndicators(void)
  {
    this.informFlg = false;

    this.calMacdLvl();
    this.calStoLvl();
    this.calCciLvl();

    if (this.macdLvl != NONE || this.stochasticLvl != NONE || this.cciLvl != NONE)
      if (!(this.macdLvl == this.preMacdLvl &&
            this.stochasticLvl == this.preStochasticLvl &&
            this.cciLvl == this.preCciLvl))
        this.informFlg = true;

  }
//+------------------------------------------------------------------+
//| get email text for the trading pair                              |
//+------------------------------------------------------------------+
string Fx24::getInformText(void)
  {
    string text = this.sym + "(" +
                  DoubleToString((MarketInfo(this.sym, MODE_ASK)+MarketInfo(this.sym, MODE_BID))/2, 5) +
                  "): ";

    if (this.informFlg) {
       string s = "MACD[";
       string e   = "], ";

       int lvl = this.macdLvl;
       int absLvl = fabs(lvl) - 1;
       text += s;
       if (lvl > NONE) {
         text += this.buy[absLvl];
       } else if (lvl < NONE) {
         text += this.sell[absLvl];
       } else {
         text += NONE_INFORM;
       }
       text += e;

       s = "STO[";
       lvl = this.stochasticLvl;
       absLvl = fabs(lvl) - 1;
       text += s;
       if (lvl > NONE) {
         text += this.buy[absLvl];
       } else if (lvl < NONE) {
         text += this.sell[absLvl];
       } else {
         text += NONE_INFORM;
       }
       text += e;

       s = "CCI[";
       lvl = this.cciLvl;
       absLvl = fabs(lvl) - 1;
       text += s;
       if (lvl > NONE) {
         text += this.buy[absLvl];
       } else if (lvl < NONE) {
         text += this.sell[absLvl];
       } else {
         text += NONE_INFORM;
       }
       text += e;
    }
    return text;
  }
//+------------------------------------------------------------------+
//| get email text for the trading pair                              |
//+------------------------------------------------------------------+
bool Fx24::isInform(void)
  {
     return this.informFlg;
  }
//+------------------------------------------------------------------+
//| calculate                                                        |
//+------------------------------------------------------------------+
void Fx24::calMacdLvl(void)
  {
    TradeLvl lvl = NONE;
    int scale = MarketInfo(this.sym, MODE_DIGITS) == 5? 100: 1;
    double Buy1 = -3.0;
    double Buy2 = -1.5;
    double Sell1 = 3.0;
    double Sell2 = 1.5;

    RefreshRates();
    double main = iMACD(this.sym,this.period,12,26,9,PRICE_WEIGHTED,MODE_MAIN,  0)*scale;
    double sig  = iMACD(this.sym,this.period,12,26,9,PRICE_WEIGHTED,MODE_SIGNAL,0)*scale;

    if (main < Buy1 && sig < main)
         lvl = SB;
    else if (sig < Buy1 && main < sig)
         lvl = MB;
    else if (sig < Buy2 && main < Buy2)
         lvl = WB;
    else if (main > Sell1 && sig > main)
         lvl = SS;
    else if (sig > Sell1 && main > sig)
         lvl = MS;
    else if (sig > Sell2 && main > Sell2)
         lvl = WS;
    else
         lvl = NONE;

    this.preMacdLvl = this.macdLvl;
    this.macdLvl = lvl;
  }
//+------------------------------------------------------------------+
//| calculate                                                        |
//+------------------------------------------------------------------+
void Fx24::calStoLvl(void)
  {
    TradeLvl lvl = NONE;

    double Buy1 = 10;
    double Buy2 = 20;
    double Sell1 = 90;
    double Sell2 = 80;

    RefreshRates();
    double main = iStochastic(this.sym,this.period,5,3,3,MODE_SMA,0,MODE_MAIN,  0);
    double sig  = iStochastic(this.sym,this.period,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);

    if (sig < Buy1 && main < sig)
         lvl = SB;
    else if (main < Buy1 && sig < main)
         lvl = MB;
    else if (sig < Buy2 && main < Buy2)
         lvl = WB;
    else if (sig > Sell1 && main > sig)
         lvl = SS;
    else if (main > Sell1 && sig > main)
         lvl = MS;
    else if (sig > Sell2 && main > Sell2)
         lvl = WS;
    else
         lvl = NONE;

    this.preStochasticLvl = this.stochasticLvl;
    this.stochasticLvl = lvl;
  }
//+------------------------------------------------------------------+
//| calculate                                                        |
//+------------------------------------------------------------------+
void Fx24::calCciLvl(void)
  {
    TradeLvl lvl = NONE;

    double Buy1 = -200;
    double Buy2 = -150;
    double Buy3 = -100;
    double Sell1 = 200;
    double Sell2 = 150;
    double Sell3 = 100;

    RefreshRates();
    double main = iCCI(this.sym,this.period,14,PRICE_WEIGHTED,0);

    if (main < Buy1)
         lvl = SB;
    else if (main < Buy2)
         lvl = MB;
    else if (main < Buy3)
         lvl = WB;
    else if (main > Sell1)
         lvl = SS;
    else if (main > Sell2)
         lvl = MS;
    else if (main > Sell3)
         lvl = WS;
    else
         lvl = NONE;

    this.preCciLvl = this.cciLvl;
    this.cciLvl = lvl;
  }
//+------------------------------------------------------------------+
