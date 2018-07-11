<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';
require_once __DIR__ . '/TradeInfo.php';

use Goutte\Client;
// use DS\Map;
// use DS\Vector;

/*
 *  Singleton classes
*/
class TopN2Mgr {
  private $_newTradeInfoList = NULL;
  private $_oldTopN = NULL;
  private $_dao = NULL;
  private $_client = NULL;
  // _mgr instance
  private static $_mgr = NULL;

  private function __construct() {
    $this->_dao = new RedisDao();
    $this->_client = new Client();
  }

  function __destruct() {
    unset($this->_newTradeInfoList);
    unset($this->_curTopN);
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

  function updateTradeInfoList($ts, $cur) {
    $tmp = array(5 => 1, 12 => 2);
    $prevTradeInfoList = NULL;
    // 初次处理
    if ($ts == 0) {
      // 从网页或 WebAPI 获取最新交易信息, pageId = 1,2,3
      $this->_client->crawler();
      $this->_newTradeInfoList = new \Ds\Vector();
    } else {
      // 从网页或 WebAPI 获取最新交易信息, 如果当前pageId无最新，pageIdMax = 3
      $this->_client->crawler();
      $prevTradeInfoList = $this->_dao->getHistory($ts);
    }

    if (NULL != $this->_newTradeInfoList)
      $this->_dao->setHistory($cur, $this->_newTradeInfoList);
  }

  function getNewTradeInfoList() {
    return $this->_newTradeInfoList;
  }
}
?>
