//+------------------------------------------------------------------+
//|【功能】行情跟随式止损的通常算法进阶版                            |
//|                                                                  |
//|【参数】 IN OUT  参数名             说明                          |
//|        --------------------------------------------------------- |
//|         ○      aMagic             魔法数                        |
//|         ○      aTS_StartPips      跟随步进幅值（pips）          |
//|         ○      aTS_StopPips       止损幅值（pips）              |
//|         △      aTS_StepPips       止损幅值更改阈值（pips）      |
//|                                                                  |
//|【返值】无                                                        |
//|                                                                  |
//|【备注】△：有预设值                                              |
//|        从原平仓价格处以 aTS_StartPips 幅度跟随步进，在新设定     |
//|        的平仓价格处按 aTS_StopPips 幅度设定止损位价格            |
//|        在此之后，以 aTS_StepPips 幅度跟随步进后再设置止损位价格  |
//|        a - arguments, g - global variables, o - order            |
//+------------------------------------------------------------------+
void trailingStopGeneral(int aMagic, double aTS_StartPips, double aTS_StopPips, double aTS_StepPips = 0.0)
{
  for (int i = 0; i < OrdersTotal(); i++) {
    // 任意当前订单（仓）若不存在，则结束当前及后续所有订单处理
    if (OrderSelect(i, SELECT_BY_POS) == false) {
      break;
    }

    // 取得订单币种
    string oSymbol = OrderSymbol();

    // 若订单币种同当前交易币种不一致 或 订单魔法数不匹配
    // 判断属于其他 EA 订单，忽略当前订单处理
    if (oSymbol != Symbol() || OrderMagicNumber() != aMagic) {
      continue;
    }

    // 取得订单（仓）类型
    int oType = OrderType();

    // 非多订单（仓） 及 非空订单（仓），忽略当前订单处理
    if (oType != OP_BUY && oType != OP_SELL) {
      continue;
    }

    // 当前币种的汇率行情的点位调整
    double digits = MarketInfo(oSymbol, MODE_DIGITS);

    // 按点位调整当前订单（仓）的开仓价格
    double oPrice    = NormalizeDouble(OrderOpenPrice(), digits);
    // 按点位调整当前订单（仓）的止损价格
    double oStopLoss = NormalizeDouble(OrderStopLoss(), digits);
    // 订单（仓）号
    int    oTicket   = OrderTicket();

    // 按点位调整跟随步进幅值
    double start = aTS_StartPips * gPipsPoint;
    // 按点位调整止损幅值
    double stop  = aTS_StopPips  * gPipsPoint;
    // 按点位调整止损步进幅值
    double step  = aTS_StepPips  * gPipsPoint;

    if (oType == OP_BUY) { // 若为【多】订单(仓)
      double price = MarketInfo(oSymbol, MODE_BID);   // 当前币种汇率行情的 BID 价格
      double modifyStopLoss = price - stop;           // 按止损幅值设定【新止损位价格】

      // 当前币种汇率行情的 BID 价格已经 【不低于】 开仓价格加上跟随步进幅值（低价（止损）平仓不划算）
      if (price >= oPrice + start) {
        if (modifyStopLoss > oStopLoss) { // 当前【多】订单（仓）的止损位价格低于【新止损位价格】
          if (MathAbs(modifyStopLoss - oStopLoss) >= step) { // ★ 新止损价格差【不小于】阈值
            // 修改（提高）当前【多】订单（仓）的止损位价格为【新止损位价格】
            orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
          }
        }
      }
    } else if (oType == OP_SELL) {
      price = MarketInfo(oSymbol, MODE_ASK);
      modifyStopLoss = price + stop;

      if (price <= oPrice - start) { // ❶
        if (modifyStopLoss < oStopLoss || oStopLoss == 0.0) {  // ❷ || 0.0
          if (MathAbs(modifyStopLoss - oStopLoss) >= step) {   // ❸
            orderModifyReliable(oTicket, 0.0, modifyStopLoss, 0.0, 0, gArrowColor[oType]);
          }
        }
        // 示例：usd/jpy， start = 5，stop = 3，step = 1.6
        // 在汇率 120（oPrice） 开仓做【卖空】，假定此时止损位价格指定为 127（oStopLoss = 120 + 7（任意））
        // 当汇率变动至 110（price（ASK）），按止损幅值应设定【新止损位价格】113（modifyStopLoss = 110 + 3（stop））
        // ❶ 因 110（price（ASK）） <= 115 【120（oPrice）- start (5)】并且 ❷ 113（modifyStopLoss）< 127（oStopLoss）
        // ★ ❸ 新止损价格差【不小于】阈值（abs[113 - 127] >= 1.6）
        // 即可下调 当前【空】订单（仓）的止损位价格为【新止损位价格】113（modifyStopLoss = 110 + 3）
      }
    }
  }
}
