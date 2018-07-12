<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';
require_once __DIR__ . '/topN2Mgr.php';
require_once __DIR__ . '/tradeMgr.php';

// ※ 预先保存初始 Tts 于 Redis: set(ZULU_TRADEWALL_PREV, "0")

// TopN2Mgr 获取当前时刻的 curTopN <id> List 并更新  TopN2
$topN2Mgr = TopN2Mgr::getMgr();
$topN2Mgr->updateTopN2();

// TradeMgr 获取当前时刻的 List<TradeInfo>
$tradeMgr = TradeMgr::getMgr();
$tradeMgr->updateTradeInfoList();

// 判断是否有新的交易信息
if (NULL != $tradeMgr->getNewTradeInfoList()) {

  // 对当前最新交易信息按 TopN2 进行过滤
  $toPublish = $tradeMgr->getNewTradeInfoList()->copy();
  $toPublish->filter(function ($info) use ($topN2Mgr) {
    return $topN2Mgr->filterTradeInfo($info);
  });

  // 判断经 TopN2 过滤后是否需要发布
  if (!$toPublish->isEmpty()) {

    // Publish
  }
}

// 保存 TopN2 (in Redis)
$topN2Mgr->saveTopN2();

// uninit
unset(TopN2Mgr::getMgr());
unset(TradeMgr::getMgr());
?>
