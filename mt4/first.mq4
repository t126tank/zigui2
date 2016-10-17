//+------------------------------------------------------------------+
//|                                                        first.mq4 |
//|                                                    Author Person |
//|                                        http://www.aabbccddee.com |
//+------------------------------------------------------------------+

// 复数仓位交易及管理模板
#property copyright "Copyright (c) 2016, Zigui"
#property link      "http://aa.bb.cc.ee.com/"

// 原始库文件
#define POSITIONS 2                 // 两仓
#define MAGIC 123454321             // 魔法数：仓位区分
#include <Zigui\LibPosition.mqh>    // 

// 进入信号
//#include <Zigui\EntryRSI.mqh>
#include <Zigui\EntryBBCross.mqh>

// 退出信号
#include <Zigui\ExitEntry.mqh>
//#include <Zigui\ExitTrailingStop.mqh>
//#include <Zigui\ExitTime.mqh>
//#include <Zigui\ExitMACross0.mqh>

// 交易信号过滤
#include <Zigui\NoFilter.mqh>
//#include <Zigui\FilterTrend.mqh>
//#include <Zigui\FilterTime.mqh>

// 交易 Lot 数
#include <Zigui\LotsFixed.mqh>
//#include <Zigui\LotsStopLoss.mqh>
//#include <Zigui\LotsATR.mqh>
//#include <Zigui\LotsMartingale.mqh>
//#include <Zigui\LotsAntiMartingale.mqh>

input int WaitingMin = 120; // 待机时间（分钟）

// 在 tick 时刻执行函数
void OnTick()
{
   UpdatePosition();    // 更新仓位信息

   int sig_entry = EntrySignal(0);  // 1号仓处置信号
   int sig_entry1 = EntrySignal(1); // 2号仓处置信号

   // 根据退出信号手平仓
   bool sig_exit = ExitSignal(sig_entry, 0); // 退出信号
   if (sig_exit) {
      MyOrderClose(0); // 1号仓平仓
      MyOrderClose(1); // 2号仓平仓
   }

   // 过滤1号仓处置信号
   sig_entry = FilterSignal(sig_entry, 0);
   // 过滤2号仓处置信号
   sig_entry1 = FilterSignal(sig_entry1, 1);

   // 待机模式过滤2号仓处置信号
   sig_entry1 = WaitSignal(sig_entry1, WaitingMin, 0);

   double lots = CalculateLots(); // 交易 Lot 数

   // 1号仓下单交易
   if (sig_entry > 0) MyOrderSend(OP_BUY, lots, 0, 0);   // 建多 或 平空
   if (sig_entry < 0) MyOrderSend(OP_SELL, lots, 0, 0);  // 建空 或 平多

   // 2号仓下单交易
   if (sig_entry1 > 0) MyOrderSend(OP_BUY, lots, 0, 1);  // 建多 或 平空
   if (sig_entry1 < 0) MyOrderSend(OP_SELL, lots, 0, 1); // 建空 或 平多
}
