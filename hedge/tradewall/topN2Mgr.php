<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';

use Goutte\Client;
// use DS\Map;

/*
 *   Singleton classes
 */
class TopN2Mgr {
    private $curTopN = NULL;
    private $oldTopN = NULL;
    private $dao = NULL;
    private $client = NULL;
    // mgr instance
    private static $mgr = NULL;

    private function __construct() {
        $this->curTopN = new \Ds\Map();
        $this->oldTopN = new \Ds\Map();
        $this->dao = new RedisDao();
        $this->client = new Client();
    }

    function __destruct() {
        unset($this->curTopN);
        unset($this->curTopN);
        unset($this->dao);
        unset($this->client);

        // flock($this->handle, LOCK_UN);
        // fclose($this->handle);
        // echo 'ファイルを閉じて終了します。'.PHP_EOL;
    }

    static function getMgr() {
        if (NULL == self::$mgr) {
            self::$mgr = new TopN2Mgr();
        }
        return self::$mgr;
    }

    function fetchCurTopN($ts) {
        // 初次处理
        if ($ts == 0) {

        } else {
        }
    }

    function getCurTopN() {
        return $this->curTopN;
    }

    function getOldTopN() {
        return $this->oldTopN;
    }
}
?>
