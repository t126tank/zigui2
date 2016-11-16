//+------------------------------------------------------------------+
//|【功能】利用 ATR 指标的行情跟随式止损算法                         |
//|                                                                  |
//|【参数】 IN OUT  参数名             说明                          |
//|        --------------------------------------------------------- |
//|         ○      aMagic             魔法数                        |
//|         ○      aTS_ATR_Period     ATR 算出期间（蜡烛数）        |
//|         ○      aTS_ATR_Multi      ATR 的倍率                    |
//|                                                                  |
//|【返值】无                                                        |
//|                                                                  |
//|【备注】1つ前の足の高値／安値とATRを使って損切り値を設定          |
//+------------------------------------------------------------------+
void trailingStopATR(int aMagic, int aTS_ATR_Period, double aTS_ATR_Multi)
{
  for (int i = 0; i < OrdersTotal(); i++){
    // オーダーが１つもなければ処理終了
    if (OrderSelect(i, SELECT_BY_POS) == false) {
      break;
    }

    string oSymbol = OrderSymbol();

    // 別EAのオーダーはスキップ
    if (oSymbol != Symbol() || OrderMagicNumber() != aMagic) {
      continue;
    }

    int oType = OrderType();

    // 待機オーダーはスキップ
    if (oType != OP_BUY && oType != OP_SELL) {
      continue;
    }

    double digits = MarketInfo(oSymbol, MODE_DIGITS);

    double oPrice    = NormalizeDouble(OrderOpenPrice(), digits);
    double oStopLoss = NormalizeDouble(OrderStopLoss(), digits);
    int    oTicket   = OrderTicket();
    double stopLevel = MarketInfo(oSymbol, MODE_STOPLEVEL) * MarketInfo(oSymbol, MODE_POINT);

    double stop = iATR(oSymbol, 0, aTS_ATR_Period, 1) * aTS_ATR_Multi;

    if (oType == OP_BUY) {
      double highPrice      = iHigh(oSymbol, 0, 1);
      double price          = MarketInfo(oSymbol, MODE_BID);
      double modifyStopLoss = highPrice - stop;

      if (price - modifyStopLoss >= stopLevel) {
        if (modifyStopLoss > oStopLoss) {
          orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
        }
      }
    } else if (oType == OP_SELL) {
      // iLowはBidで算出。ショートの決済はAskになるので、スプレッドを足す必要がある
      double lowPrice = iLow(oSymbol, 0, 1) + MarketInfo(oSymbol, MODE_SPREAD); 
      price           = MarketInfo(oSymbol, MODE_ASK);
      modifyStopLoss  = lowPrice + stop;

      // ショートの場合、条件式にoStopLoss == 0.0が必要
      // oStopLoss = 0.0の場合、modifyStopLossには価格（正の値）が格納されるため、
      // modifyStopLoss < oStopLossの条件が永久に成立しなくなるため
      if (modifyStopLoss - price >= stopLevel) {
        if (modifyStopLoss < oStopLoss || oStopLoss == 0.0) {
          orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
        }
      } 
    }
  }
}

//+------------------------------------------------------------------+
//|【関数】一定期間内の最高値／最安値を用いたトレイリングストップ    |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aMagic             マジックナンバー              |
//|         ○      aTS_HL_Period      高値／安値の算出期間（本数）  |
//|                                                                  |
//|【戻値】なし                                                      |
//|                                                                  |
//|【備考】1つ前の足の高値／安値とATRを使って損切り値を設定          |
//+------------------------------------------------------------------+
void trailingStopHL(int aMagic, int aTS_HL_Period)
{
  for (int i = 0; i < OrdersTotal(); i++) {
    // オーダーが１つもなければ処理終了
    if (OrderSelect(i, SELECT_BY_POS) == false) {
      break;
    }

    string oSymbol = OrderSymbol();

    // 別EAのオーダーはスキップ
    if (oSymbol != Symbol() || OrderMagicNumber() != aMagic) {
      continue;
    }

    int oType = OrderType();

    // 待機オーダーはスキップ
    if (oType != OP_BUY && oType != OP_SELL) {
      continue;
    }

    double digits = MarketInfo(oSymbol, MODE_DIGITS);

    double oPrice    = NormalizeDouble(OrderOpenPrice(), digits);
    double oStopLoss = NormalizeDouble(OrderStopLoss(), digits);
    int    oTicket   = OrderTicket();
    double stopLevel = MarketInfo(oSymbol, MODE_STOPLEVEL) * MarketInfo(oSymbol, MODE_POINT);

    if (oType == OP_BUY) {
      double price          = MarketInfo(oSymbol, MODE_BID);
      double modifyStopLoss = iHigh(oSymbol, 0, iHighest(oSymbol, 0, MODE_HIGH, aTS_HL_Period, 1));

      if (price - modifyStopLoss >= stopLevel) {
        if (modifyStopLoss > oStopLoss) {
          orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
        }
      }
    } else if (oType == OP_SELL) {
      // iLowはBidで算出。ショートの決済はAskになるので、スプレッドを足す必要がある
      price          = MarketInfo(oSymbol, MODE_ASK);
      modifyStopLoss = iLow(oSymbol, 0, iLowest(oSymbol, 0, MODE_LOW, aTS_HL_Period, 1)) + MarketInfo(oSymbol, MODE_SPREAD);

      // ショートの場合、条件式にoStopLoss == 0.0が必要
      // oStopLoss = 0.0の場合、modifyStopLossには価格（正の値）が格納されるため、
      // modifyStopLoss < oStopLossの条件が永久に成立しなくなるため
      if (modifyStopLoss - price >= stopLevel) {
        if (modifyStopLoss < oStopLoss || oStopLoss == 0.0) {
          orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
        }
      }
    }
  }
}
