<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';
require_once __DIR__ . '/TradeInfo.php';

use Goutte\Client;
// use Ds\Map;
// use Ds\Vector;

/*
 *  Singleton classes
*/
class TopN2Mgr {
  private $_newTradeInfoList = NULL;
  private $_dao = NULL;
  private $_client = NULL;
  // _mgr instance
  private static $_mgr = NULL;

  private function __construct() {
    $this->_dao = new RedisDao();
    $this->_client = new Client();
  }

  function __destruct() {
    if (NULL != $this->_newTradeInfoList) {
      $this->_newTradeInfoList->clear();
      unset($this->_newTradeInfoList);
    }
    unset($this->_dao);
    unset($this->_client);

    // flock($this->handle, LOCK_UN);
    // fclose($this->handle);
    // echo 'ファイルを閉じて終了します。'.PHP_EOL;
  }

  static function getMgr() {
    if (NULL == self::$_mgr) {
      self::$_mgr = new TopN2Mgr();
    }
    return self::$_mgr;
  }

  function updateTradeInfoList() {
    $prev = $this->_dao->getPrevTimestamp();
    $pageIdMax = 3;

    $tmpArr = array();
    $tmp["id"] = "id1";
    $tmp["pair"]= "usd/jpy";
    $tmp["op"]= "sell";
    $tmp["price"] = 110.34;
    $tmp["pl"] = -99999;
    $tmpArr[] = $tmp;

    $tmp["id"] = "id1";
    $tmp["pair"] = "eur/jpy";
    $tmp["op"]= "sell";
    $tmpArr[] = $tmp;

    $tmp["id"] = "id2";
    $tmp["pair"] = "eur/jpy";
    $tmp["op"]= "buy";
    $tmp["pl"] = 1.223;
    $tmpArr[] = $tmp;

    // 初次处理
    if ($prev == 0) {
      // 从网页或 WebAPI 获取最新交易信息, pageId = 1,2,3
      $this->_client->crawler(1, 2, 3);
      $this->_newTradeInfoList = new \Ds\Vector();
      $this->_newTradeInfoList->push(...$tmpArr);
    } else {
      $prevTradeInfoList = $this->_dao->getHistory($prev);
      $newList = new \Ds\Vector();
      $tmpVec = new \Ds\Vector();

      // 从网页或 WebAPI 获取最新交易信息, 如果当前pageId无最新，pageIdMax = 3
      // TODO: 存在丢失信号的风险 tolerance
      while ($pageIdMax--) {
        $tmpVec->clear();

        $this->_client->crawler(3 - $pageIdMax);
        $tmpVec->push(...$tmpArr);
        $newList->push(...$tmpArr);

        // 判断同前次是否有重叠
        if (isPrevListHasNew($prevTradeInfoList, $tmpVec))  break; // 有重叠
      }

      $tmpVec->clear();
      unset($tmpVec);

      // 过滤掉重叠部分
      $newList->filter(function($info) use ($prevTradeInfoList) {
        return !$prevTradeInfoList->contains($info);
      });

      // 全部重叠 - 无实际最新交易信息
      if ($newList->isEmpty()) {
        unset($newList);
        // $this->_newTradeInfoList = NULL;
        return;
      }

      $this->_newTradeInfoList = $newList;
    }

    // 保存当次交易 的 timestamp 及 最新交易信息
    $curr = time();
    $this->_dao->setPrevTimestamp($curr);
    $this->_dao->setHistory($curr, $this->_newTradeInfoList);
  }

  function getNewTradeInfoList() {
    return $this->_newTradeInfoList;
  }

  private function isPrevListHasNew($prevVec, $newVec) {
    foreach ($newVec as $info)
      // 有重叠
      if ($prevVec->contains($info)) return true;

    return false;
  }
}
?>
