<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/TradeInfo.php';
require_once __DIR__ . '/TradeUtils.php';

/*
 *  Singleton classes
*/
class TradeMgr {
  private $_newTradeInfoList = NULL;
  private $_dao = NULL;
  // _mgr instance
  private static $_mgr = NULL;

  private function __construct() {
    $this->_dao = new RedisDao();
  }

  function __destruct() {
    if (NULL != $this->_newTradeInfoList) {
      $this->_newTradeInfoList->clear();
      unset($this->_newTradeInfoList);
    }
    unset($this->_dao);
  }

  static function getMgr() {
    if (NULL == self::$_mgr) {
      self::$_mgr = new TradeMgr();
    }
    return self::$_mgr;
  }

  function updateTradeInfoList() {
    $prev = $this->_dao->getPrevTimestamp();

    // 初次处理
    if ($prev == 0) {
      // 从网页或 WebAPI 获取最新交易信息, pageId = 1,2,3
      $this->_newTradeInfoList = new \Ds\Vector();

      $pageIdMax = 3;
      while ($pageIdMax--) {
        $tmpArr = TradeCrawler::getTradewall(3 - $pageIdMax);
        $this->_newTradeInfoList->push(...$tmpArr);
      }
    } else {
      $prevTradeInfoVec = $this->_dao->getHistory($prev);
      $newList = new \Ds\Vector();
      $tmpVec = new \Ds\Vector();

      // 从网页或 WebAPI 获取最新交易信息, 如果当前pageId无最新，pageIdMax = 8
      // TODO: 存在丢失信号的风险 tolerance
      $pageIdMax = 8; // max = 8 * 100
      while ($pageIdMax--) {
        $tmpVec->clear();

        $tmpArr = TradeCrawler::getTradewall(8 - $pageIdMax);
        $tmpVec->push(...$tmpArr);
        $newList->push(...$tmpArr);

        // 判断同前次是否有重叠
        if (!$tmpVec->filter(function($info) use ($prevTradeInfoVec) {
            foreach ($prevTradeInfoVec as $v)
              if ($info->equals($v))
                return true;

            return false;
          })->isEmpty())
          break; // 有重叠
      }

      $tmpVec->clear();
      unset($tmpVec);

      // 过滤掉重叠部分
      $newList = $newList->filter(function($info) use ($prevTradeInfoVec) {
        foreach ($prevTradeInfoVec as $v)
          if ($info->equals($v))
            return false; // if exists, drop

        return true;
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

  public function getNewTradeInfoList() {
    return $this->_newTradeInfoList;
  }
}
?>
