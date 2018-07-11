<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';

use Goutte\Client;
// use DS\Map;

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

  function updateTopN2($ts) {
    // 从网页或 WebAPI 获取最新排行榜
    $this->_client->crawler();

    // 初次处理
    if ($ts == 0) {
      $this->_curTopN = new \Ds\Map();
      $this->_oldTopN = new \Ds\Map();
    } else {
      $this->_curTopN = $this->_dao->getCurTopN();
      $this->_oldTopN = $this->_dao->getOldTopN();
    }
  }

  function getCurTopN() {
    return $this->_curTopN;
  }

  function getOldTopN() {
    return $this->_oldTopN;
  }
}
?>
