<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);
require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';
require_once __DIR__ . '/topN2Mgr.php';
require_once __DIR__ . '/tradeMgr.php';

// ※ 预先保存初始 Tts 于 Redis: set(ZULU_TRADEWALL_PREV, "0")
// 分别获取当前以及前一时刻 Trade 的 timestamp
$currTts = time();
$prevTts = $dao->getPrevTimestamp();

// TopN2Mgr 获取当前时刻的 curTopN <id> List 并更新  TopN2
$topN2Mgr = TopN2Mgr::getMgr();
$topN2Mgr->updateTopN2($prevTts);

// TradeMgr 获取当前时刻的 List<TradeInfo>
$tradeMgr = TradeMgr::getMgr();
$tradeMgr->updateTradeInfoList($prevTts, $currTts);

// 判断是否有新的交易信息
if (NULL != $tradeMgr->hasNewInfo()) {

  // 保存当次 Trade 的 timestamp
  $dao->setPrevTimestamp($currTts);
}

// uninitialization
unset(TopN2Mgr::getMgr());
unset(TradeMgr::getMgr());
?>
