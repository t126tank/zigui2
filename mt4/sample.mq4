//+------------------------------------------------------------------+
//|                                                       Sample.mq4 |
//|                                     Copyright (c) 2015, りゅーき |
//|                                            http://autofx100.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2015, りゅーき"
#property link      "http://autofx100.com/"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ライブラリ                                                       |
//+------------------------------------------------------------------+
#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| インポート                                                       |
//+------------------------------------------------------------------+
// なし

//+------------------------------------------------------------------+
//| 定数定義                                                         |
//+------------------------------------------------------------------+
#define MAX_RETRY_TIME   10.0 // 秒
#define SLEEP_TIME        0.1 // 秒
#define MILLISEC_2_SEC 1000.0 // ミリ秒

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern string Note01         = "=== General ==================================================";
extern int    MagicNumber    = 7777777;
extern int    SlippagePips   = 5;
extern double LotSize        = 0.01;
extern string Comments       = "";

extern string Note02         = "=== Exit =====================================================";
extern double InitialSL_Pips = 50.0;
extern string Note02_1       = "--- Trailing Stop --------------------------------------------";
extern double TS_StartPips   = 10.0;
extern double TS_StopPips    = 5.0;

//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
double gPipsPoint     = 0.0;
int    gSlippage      = 0;
color  gArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red}; //BUY: Blue, SELL: Red

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  gPipsPoint = currencyUnitPerPips(Symbol());
  gSlippage = getSlippage(Symbol(), SlippagePips);

  // 成行注文
  int ticket = orderSendReliableRange(Symbol(), OP_BUY, LotSize, Ask, gSlippage, InitialSL_Pips, 0.0, Comments, MagicNumber, 0, gArrowColor[OP_BUY]);

  ticket = orderSendReliableRange(Symbol(), OP_SELL, LotSize, Bid, gSlippage, InitialSL_Pips, 0.0, Comments, MagicNumber, 0, gArrowColor[OP_SELL]);

  // 本来はticketの値によって後続の処理を制御する必要があるが、簡単のため、ここでは無視

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  trailingStopGeneral(MagicNumber, TS_StartPips, TS_StopPips);
}

//+------------------------------------------------------------------+
//|【関数】信頼できる仕掛け注文（値幅指定）                          |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aSymbol            通貨ペア                      |
//|         ○      aCmd               注文種別                      |
//|         ○      aVolume            ロット数                      |
//|         ○      aPrice             仕掛け価格                    |
//|         ○      aSlippage          スリッページ（ポイント）      |
//|         ○      aStoploss          損切り価格                    |
//|         ○      aTakeprofit        利食い価格                    |
//|         △      aComment           コメント                      |
//|         △      aMagic             マジックナンバー              |
//|         △      aExpiration        待機注文の有効期限            |
//|         △      aArrow_color       チャート上の矢印の色          |
//|                                                                  |
//|【戻値】チケット番号（エラーの場合は、-1）                        |
//|                                                                  |
//|【備考】△：初期値あり                                            |
//+------------------------------------------------------------------+
int orderSendReliableRange(string aSymbol, int aCmd, double aVolume, double aPrice, int aSlippage, double aStoplossPips, double aTakeprofitPips, string aComment = NULL, int aMagic = 0, datetime aExpiration = 0, color aArrow_color = CLR_NONE)
{
  int plusMinusSign = 1;

  if(aCmd == OP_SELL || aCmd == OP_SELLLIMIT || aCmd == OP_SELLSTOP){
    plusMinusSign *= -1;
  }

  double sl = 0.0;
  double tp = 0.0;

  if(aStoplossPips > 0.0){
    sl = aPrice - aStoplossPips * gPipsPoint * plusMinusSign;
  }

  if(aTakeprofitPips > 0.0){
    tp = aPrice + aTakeprofitPips * gPipsPoint * plusMinusSign;
  }

  int result = orderSendReliable(aSymbol, aCmd, aVolume, aPrice, aSlippage, sl, tp, aComment, aMagic, aExpiration, aArrow_color);

  return(result);
}

//+------------------------------------------------------------------+
//|【関数】信頼できる仕掛け注文                                      |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aSymbol            通貨ペア                      |
//|         ○      aCmd               注文種別                      |
//|         ○      aVolume            ロット数                      |
//|         ○      aPrice             仕掛け価格                    |
//|         ○      aSlippage          スリッページ（ポイント）      |
//|         ○      aStoploss          損切り価格                    |
//|         ○      aTakeprofit        利食い価格                    |
//|         △      aComment           コメント                      |
//|         △      aMagic             マジックナンバー              |
//|         △      aExpiration        待機注文の有効期限            |
//|         △      aArrow_color       チャート上の矢印の色          |
//|                                                                  |
//|【戻値】チケット番号（エラーの場合は、-1）                        |
//|                                                                  |
//|【備考】△：既定値あり                                            |
//+------------------------------------------------------------------+
int orderSendReliable(string aSymbol, int aCmd, double aVolume, double aPrice, int aSlippage, double aStoploss, double aTakeprofit, string aComment = NULL, int aMagic = 0, datetime aExpiration = 0, color aArrow_color = CLR_NONE)
{
  int ticket = -1;

  int startTime = GetTickCount();

  Print("Attempted orderSendReliable(" + aSymbol + ", " + orderType2String(aCmd) + ", " + aVolume + "lots, " + aPrice + ", Slippage:" + aSlippage + ", SL:"+ aStoploss + ", TP:" + aTakeprofit + ", Comment:" + aComment + ", Magic:" + aMagic + ", Expiration:" + TimeToStr(aExpiration) + ", ArrowColor:" + aArrow_color + ")");

  double digits = MarketInfo(aSymbol, MODE_DIGITS);

  aStoploss   = NormalizeDouble(aStoploss,   digits);
  aTakeprofit = NormalizeDouble(aTakeprofit, digits);

  double stopLevel   = MarketInfo(aSymbol, MODE_STOPLEVEL) * MarketInfo(aSymbol, MODE_POINT);
  double freezeLevel = MarketInfo(aSymbol, MODE_FREEZELEVEL) * MarketInfo(aSymbol, MODE_POINT);

  while(true){
    if(IsStopped()){
      Print("Trading is stopped!");
      return(-1);
    }

    if(GetTickCount() - startTime > MAX_RETRY_TIME * MILLISEC_2_SEC){
      Print("Retry attempts maxed at " + MAX_RETRY_TIME + "sec");
      return(-1);
    }

    // MarketInfo関数でレートを取得しており、定義済変数であるAskとBidは未使用のため、不要のはずだけど、念のため
    RefreshRates();

    double ask = NormalizeDouble(MarketInfo(aSymbol, MODE_ASK), digits);
    double bid = NormalizeDouble(MarketInfo(aSymbol, MODE_BID), digits);

    if(aCmd == OP_BUY){
      aPrice = ask;
    }else if(aCmd == OP_SELL){
      aPrice = bid;
    }

    // 仕掛け／損切り／利食いがストップレベル未満かフリーズレベル以下の場合、エラー
    if(aCmd == OP_BUY){
      if(MathAbs(bid - aStoploss) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - bid) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(bid - aStoploss) <= freezeLevel){
        Print("FreezeLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - bid) <= freezeLevel){
        Print("FreezeLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(aCmd == OP_SELL){
      if(MathAbs(aStoploss - ask) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(ask - aTakeprofit) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aStoploss - ask) <= freezeLevel){
        Print("FreezeLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(ask - aTakeprofit) <= freezeLevel){
        Print("FreezeLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(aCmd == OP_BUYLIMIT){
      if(MathAbs(ask - aPrice) < stopLevel){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aStoploss) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - aPrice) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(ask - aPrice) <= freezeLevel){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(aCmd == OP_SELLLIMIT){
      if(MathAbs(aPrice - bid) < stopLevel){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aStoploss - aPrice) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aTakeprofit) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - bid) <= freezeLevel){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(aCmd == OP_BUYSTOP){
      if(MathAbs(aPrice - ask) < stopLevel){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aStoploss) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - aPrice) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - ask) <= freezeLevel){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(aCmd == OP_SELLSTOP){
      if(MathAbs(bid - aPrice) < stopLevel){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aStoploss - aPrice) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aTakeprofit) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(bid - aPrice) <= freezeLevel){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }

    if(IsTradeContextBusy()){
      Print("Must wait for trade context");
    }else{
      ticket = OrderSend(aSymbol, aCmd, aVolume, aPrice, aSlippage, aStoploss, aTakeprofit, aComment, aMagic, aExpiration, aArrow_color);

      if(ticket > 0){
        Print("Success! Ticket #", ticket, " ", orderType2String(aCmd), " order placed, details follow");
        bool selected = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
        OrderPrint();
        return(ticket);
      }

      int err = GetLastError();

      // 一時的エラーの場合はリトライするが、恒常的エラーの場合は処理中断（リトライしてもエラーになるため）
      if(err == ERR_NO_ERROR || 
         err == ERR_COMMON_ERROR ||
         err == ERR_SERVER_BUSY ||
         err == ERR_NO_CONNECTION ||
         err == ERR_TRADE_TIMEOUT ||
         err == ERR_INVALID_PRICE ||
         err == ERR_PRICE_CHANGED ||
         err == ERR_OFF_QUOTES ||
         err == ERR_BROKER_BUSY ||
         err == ERR_REQUOTE ||
         err == ERR_TRADE_CONTEXT_BUSY){
        Print("Temporary Error: " + err + " " + ErrorDescription(err) + ". waiting");
      }else{
        Print("Permanent Error: " + err + " " + ErrorDescription(err) + ". giving up");
        return(-1);
      }

      // 最適化とバックテスト時はリトライは不要
      if(IsOptimization() || IsTesting()){
        return(-1);
      }
    }

    Sleep(SLEEP_TIME * MILLISEC_2_SEC);
  }

  return(-1);
}

//+------------------------------------------------------------------+
//|【関数】信頼できる注文変更                                        |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aTicket            チケット番号                  |
//|         ○      aPrice             待機注文の新しい仕掛け価格    |
//|         ○      aStoploss          損切り価格                    |
//|         ○      aTakeprofit        利食い価格                    |
//|         ○      aExpiration        待機注文の有効期限            |
//|         △      aArrow_color       チャート上の矢印の色          |
//|                                                                  |
//|【戻値】true ：正常終了                                           |
//|        false：異常終了                                           |
//|                                                                  |
//|【備考】△：既定値あり                                            |
//+------------------------------------------------------------------+
bool orderModifyReliable(int aTicket, double aPrice, double aStoploss, double aTakeprofit, datetime aExpiration, color aArrow_color = CLR_NONE)
{
  bool result = false;

  int startTime = GetTickCount();

  Print("Attempted orderModifyReliable(#" + aTicket + ", " + aPrice + ", SL:"+ aStoploss + ", TP:" + aTakeprofit + ", Expiration:" + TimeToStr(aExpiration) + ", ArrowColor:" + aArrow_color + ")");

  bool selected = OrderSelect(aTicket, SELECT_BY_TICKET, MODE_TRADES);

  string symbol = OrderSymbol();
  int    type   = OrderType();

  double digits = MarketInfo(symbol, MODE_DIGITS);

  double price      = NormalizeDouble(OrderOpenPrice(), digits);
  double stoploss   = NormalizeDouble(OrderStopLoss(), digits);
  double takeprofit = NormalizeDouble(OrderTakeProfit(), digits);

  aPrice      = NormalizeDouble(aPrice,      digits);
  aStoploss   = NormalizeDouble(aStoploss,   digits);
  aTakeprofit = NormalizeDouble(aTakeprofit, digits);

  double stopLevel   = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
  double freezeLevel = MarketInfo(symbol, MODE_FREEZELEVEL) * MarketInfo(symbol, MODE_POINT);

  while(true){
    if(IsStopped()){
      Print("Trading is stopped!");
      return(-1);
    }

    if(GetTickCount() - startTime > MAX_RETRY_TIME * MILLISEC_2_SEC){
      Print("Retry attempts maxed at " + MAX_RETRY_TIME + "sec");
      return(-1);
    }

    double ask = NormalizeDouble(MarketInfo(symbol, MODE_ASK), digits);
    double bid = NormalizeDouble(MarketInfo(symbol, MODE_BID), digits);

    // 仕掛け／損切り／利食いがストップレベル未満かフリーズレベル以下の場合、エラー
    if(type == OP_BUY){
      if(MathAbs(bid - aStoploss) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - bid) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(bid - aStoploss) <= freezeLevel){
        Print("FreezeLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - bid) <= freezeLevel){
        Print("FreezeLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(type == OP_SELL){
      if(MathAbs(aStoploss - ask) < stopLevel){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(ask - aTakeprofit) < stopLevel){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aStoploss - ask) <= freezeLevel){
        Print("FreezeLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(ask - aTakeprofit) <= freezeLevel){
        Print("FreezeLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(type == OP_BUYLIMIT){
      if(MathAbs(ask - aPrice) < stopLevel && (aPrice != 0.0 && aPrice != price)){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aStoploss) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(ask - aPrice) <= freezeLevel && (aPrice != 0.0 && aPrice != price)){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(type == OP_SELLLIMIT){
      if(MathAbs(aPrice - bid) < stopLevel && (aPrice != 0.0 && aPrice != price)){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aStoploss - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aTakeprofit) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - bid) <= freezeLevel && (aPrice != 0.0 && aPrice != price)){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(type == OP_BUYSTOP){
      if(MathAbs(aPrice - ask) < stopLevel && (aPrice != 0.0 && aPrice != price)){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aStoploss) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aTakeprofit - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - ask) <= freezeLevel && (aPrice != 0.0 && aPrice != price)){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }else if(type == OP_SELLSTOP){
      if(MathAbs(bid - aPrice) < stopLevel && (aPrice != 0.0 && aPrice != price)){
        Print("StopLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aStoploss - aPrice) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aStoploss != 0.0 && aStoploss != stoploss))){
        Print("StopLevel: SL was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(aPrice - aTakeprofit) < stopLevel && ((aPrice != 0.0 && aPrice != price) || (aTakeprofit != 0.0 && aTakeprofit != takeprofit))){
        Print("StopLevel: TP was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }else if(MathAbs(bid - aPrice) <= freezeLevel && (aPrice != 0.0 && aPrice != price)){
        Print("FreezeLevel: OpenPrice was too close to brokers min distance (" + stopLevel + ")");
        return(-1);
      }
    }

    if(IsTradeContextBusy()){
      Print("Must wait for trade context");
    }else{
      result = OrderModify(aTicket, aPrice, aStoploss, aTakeprofit, aExpiration, aArrow_color);

      if(result){
        Print("Success! Ticket #", aTicket, " order modified, details follow");
        selected = OrderSelect(aTicket, SELECT_BY_TICKET, MODE_TRADES);
        OrderPrint();
        return(result);
      }

      int err = GetLastError();

      // 一時的エラーの場合はリトライするが、恒常的エラーの場合は処理中断（リトライしてもエラーになるため）
      if(err == ERR_NO_ERROR || 
         err == ERR_COMMON_ERROR ||
         err == ERR_SERVER_BUSY ||
         err == ERR_NO_CONNECTION ||
         err == ERR_TRADE_TIMEOUT ||
         err == ERR_INVALID_PRICE ||
         err == ERR_PRICE_CHANGED ||
         err == ERR_OFF_QUOTES ||
         err == ERR_BROKER_BUSY ||
         err == ERR_REQUOTE ||
         err == ERR_TRADE_CONTEXT_BUSY){
        Print("Temporary Error: " + err + " " + ErrorDescription(err) + ". waiting");
      }else{
        Print("Permanent Error: " + err + " " + ErrorDescription(err) + ". giving up");
        return(result);
      }

      // 最適化とバックテスト時はリトライは不要
      if(IsOptimization() || IsTesting()){
        return(result);
      }
    }

    Sleep(SLEEP_TIME * MILLISEC_2_SEC);
  }

  return(result);
}

//+------------------------------------------------------------------+
//|【関数】一般的なトレイリングストップ                              |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aMagic             マジックナンバー              |
//|         ○      aTS_StartPips      ﾄﾚｲﾘﾝｸﾞｽﾄｯﾌﾟ開始値幅（pips）  |
//|         ○      aTS_StopPips       損切り値幅（pips）            |
//|                                                                  |
//|【戻値】なし                                                      |
//|                                                                  |
//|【備考】仕掛け位置からaTS_StartPips順行したら、その位置か         |
//|        aTS_StopPips逆行した位置にストップを設定                  |
//+------------------------------------------------------------------+
void trailingStopGeneral(int aMagic, double aTS_StartPips, double aTS_StopPips)
{
  for(int i = 0; i < OrdersTotal(); i++){
    // オーダーが１つもなければ処理終了
    if(OrderSelect(i, SELECT_BY_POS) == false){
      break;
    }

    string oSymbol = OrderSymbol();

    // 別EAのオーダーはスキップ
    if(oSymbol != Symbol() || OrderMagicNumber() != aMagic){
      continue;
    }

    int oType = OrderType();

    // 待機オーダーはスキップ
    if(oType != OP_BUY && oType != OP_SELL){
      continue;
    }

    double digits = MarketInfo(oSymbol, MODE_DIGITS);

    double oPrice    = NormalizeDouble(OrderOpenPrice(), digits);
    double oStopLoss = NormalizeDouble(OrderStopLoss(), digits);
    int    oTicket   = OrderTicket();

    double start = aTS_StartPips * gPipsPoint;
    double stop  = aTS_StopPips  * gPipsPoint;

    if(oType == OP_BUY){
      double price = MarketInfo(oSymbol, MODE_BID);
      double modifyStopLoss = price - stop;

      if(price >= oPrice + start){
        if(modifyStopLoss > oStopLoss){
          orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
        }
      }
    }else if(oType == OP_SELL){
      price = MarketInfo(oSymbol, MODE_ASK);
      modifyStopLoss = price + stop;

      if(price <= oPrice - start){
        // ショートの場合、条件式にoStopLoss == 0.0が必要
        // oStopLoss=0は、損切り値を設定していない場合
        // その場合、modifyStopLoss < oStopLossの条件は永久に成立しない（※）ため
        // ※「modifyStopLoss < 0」でかつ「modifyStopLossは価格なので0以上」のため
        if(modifyStopLoss < oStopLoss || oStopLoss == 0.0){
          orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//|【関数】注文種別の数値を文字列に変換する                          |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aType              注文種別                      |
//|                                                                  |
//|【戻値】注文種別の数値に対応する文字列                            |
//|                                                                  |
//|【備考】なし                                                      |
//+------------------------------------------------------------------+
string orderType2String(int aType)
{
  if(aType == OP_BUY){
    return("BUY");
  }else if(aType == OP_SELL){
    return("SELL");
  }else if(aType == OP_BUYSTOP){
    return("BUY STOP");
  }else if(aType == OP_SELLSTOP){
    return("SELL STOP");
  }else if(aType == OP_BUYLIMIT){
    return("BUY LIMIT");
  }else if(aType == OP_SELLLIMIT){
    return("SELL LIMIT");
  }else{
    return("None (" + aType + ")");
  }
}

//+------------------------------------------------------------------+
//|【関数】1pips当たりの価格単位を計算する                           |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aSymbol            通貨ペア                      |
//|                                                                  |
//|【戻値】1pips当たりの価格単位                                     |
//|                                                                  |
//|【備考】なし                                                      |
//+------------------------------------------------------------------+
double currencyUnitPerPips(string aSymbol)
{
  // 通貨ペアに対応する小数点数を取得
  double digits = MarketInfo(aSymbol, MODE_DIGITS);

  // 通貨ペアに対応するポイント（最小価格単位）を取得
  // 3桁/5桁のFX業者の場合、0.001/0.00001
  // 2桁/4桁のFX業者の場合、0.01/0.0001
  double point = MarketInfo(aSymbol, MODE_POINT);

  // 価格単位の初期化
  double currencyUnit = 0.0;

  // 3桁/5桁のFX業者の場合
  if(digits == 3.0 || digits == 5.0){
    currencyUnit = point * 10.0;
  // 2桁/4桁のFX業者の場合
  }else{
    currencyUnit = point;
  }

  return(currencyUnit);
}

//+------------------------------------------------------------------+
//|【関数】ポイント換算した許容スリッページを計算する                |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aSymbol            通貨ペア                      |
//|         ○      aSlippagePips      許容スリッページ（pips）      |
//|                                                                  |
//|【戻値】許容スリッページ（ポイント）                              |
//|                                                                  |
//|【備考】なし                                                      |
//+------------------------------------------------------------------+
int getSlippage(string aSymbol, int aSlippagePips)
{
  double digits = MarketInfo(aSymbol, MODE_DIGITS);
  int slippage = 0;

  // 3桁/5桁業者の場合
  if(digits == 3.0 || digits == 5.0){
    slippage = aSlippagePips * 10;
  // 2桁/4桁業者の場合
  }else{
    slippage = aSlippagePips;
  }

  return(slippage);
}
