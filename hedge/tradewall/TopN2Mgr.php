<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';
require_once __DIR__ . '/TradeInfo.php';

use Goutte\Client;
// use Ds\Map;

/*
 *  Singleton classes
*/
class TopN2Mgr {
  private $_curTopN = NULL;
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
    unset($this->_curTopN);
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

  function updateTopN2() {
    // 从网页或 WebAPI 获取最新排行榜 - curTopN <id> List
    $this->_client->crawler();
    $newTopVec = new \Ds\Vector();
    $newTopVec->push(...["id1", "id2", "id3"]); // trim()

    // 准备新的 TopN
    $curTopN = new \Ds\Map();

    // prepare status of Map<pair, state> for each id
    foreach ($newTopVec as $id) {
      $status = new \Ds\Map();
      $curTopN->put($id, $status);
    }

    // 初次处理
    if ($this->_dao->getPrevTimestamp() == 0) {
      $oldTopN = new \Ds\Map();
    } else {
      // 从 Redis 取得 TopN2
      $curTopN = $this->_dao->getCurTopN();
      $oldTopN = $this->_dao->getOldTopN();
    }

    // 更新 TopN2
    $this->_curTopN = $curTopN;
    $this->_oldTopN = $oldTopN;
  }

  function saveTopN2() {
    $this->_dao->setCurTopN($this->_curTopN);
    $this->_dao->setOldTopN($this->_oldTopN);
  }

  public function filterTradeInfo(TradeInfo $info) {
    $rtn = false;

    return $rtn;
  }
  private function getCurTopN() {
    return $this->_curTopN;
  }

  private function getOldTopN() {
    return $this->_oldTopN;
  }
}
?>
