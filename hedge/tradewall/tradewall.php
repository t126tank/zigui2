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

// TopN2Mgr 获取当前时刻的 curTopN <id> List
$topN2Mgr = TopN2Mgr::getMgr();
$topN2Mgr->fetchCurTopN($currTts);

// TradeMgr 获取当前时刻的 List<TradeInfo>
$tradeMgr = TradeMgr::getMgr();
$tradeMgr->fetchCurTradeInfoList($currTts);

// 初次处理
if ($preTts == 0) {

} else {
}

//Enter your code here, enjoy!

$array = array("1" => "PHP code tester Sandbox Online",  
              "foo" => "bar", 5 , 5 => 89009, 
              "case" => "Random Stuff: " . rand(100,999),
              "PHP Version" => phpversion()
              );
              
foreach( $array as $key => $value ){
    echo $key."\t=>\t".$value."\n";
}

    // 保存当次 Trade 的 timestamp
    $dao->setPrevTimestamp($currTts);

    // uninitialization
    unset(TopN2Mgr::getMgr());
    unset(TradeMgr::getMgr());
?>
