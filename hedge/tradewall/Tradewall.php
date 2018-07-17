<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

// require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/TopN2Mgr.php';
require_once __DIR__ . '/TradeMgr.php';

// ※ 预先保存初始 Tts 于 Redis: set(ZULU_TRADEWALL_PREV, "0")

// TopN2Mgr 获取当前时刻的 curTopN <id> List 并更新  TopN2
$topN2Mgr = TopN2Mgr::getMgr();
$topN2Mgr->updateTopN2();

// TradeMgr 获取当前时刻的 List<TradeInfo>
$tradeMgr = TradeMgr::getMgr();
$tradeMgr->updateTradeInfoList();

// 对当前最新交易信息按 TopN2 进行过滤
$toPublish = new \Ds\Vector($tradeMgr->getNewTradeInfoList()); // Due to copy() is shallow copy
$toPublish->filter(function ($info) use ($topN2Mgr) {  // TODO: &$topN2Mgr ?
  return $topN2Mgr->filterTradeInfo($info);
});

// 判断经 TopN2 过滤后是否需要发布
if (!$toPublish->isEmpty()) {

  // Publish
}
unset($toPublish);

// 保存 TopN2 (into Redis)
$topN2Mgr->saveTopN2();

// uninit
unset($topN2Mgr);
unset($tradeMgr);
?>
