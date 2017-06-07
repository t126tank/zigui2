<?php
class RedisDAO {
    /*
     * 1 --- Market
     * 1.1 - Key: history
     * 1.2 - Key: last
     * 2 --- Trade
     * 2.1 - Key: userId:timestamp
     * 2.2 - Key: startup
     */
    const HISTORY = "history"; // 1.1
    const LAST = "last"; // 1.2
    const STARTUP = "startup"; // 2.2
    
    private $_redis = NULL;

    function __construct() {
        $this->_redis = new Redis();

        $this->_redis->connect("127.0.0.1", 6379);
        $this->_redis->select(1);
    }

    function __destruct() {
        $this->_redis->close();
        unset($this->_redis);
    }

    /* 1.1 */
    function getMarketHistoryOne($timestamp) {
        $jsonStr = (string) NULL;
        $this->_redis->select(1);

        $jsonStr = $this->_redis->hGet(self::HISTORY, $timestamp);
        return json_decode($jsonStr, true);
    }
    function setMarketHistoryOne($field, $value) {
        $this->_redis->select(1);

        $this->_redis->hSet(self::HISTORY, $field, json_encode($value));
    }
    /* 1.2 */
    function getMarketLastTimestamp() {
        $this->_redis->select(1);

        return $this->_redis->hGet(self::LAST, self::LAST);
    }
    function setMarketLastTimestamp($value) {
        $this->_redis->select(1);
        
        $this->_redis->hSet(self::LAST, self::LAST, json_encode($value));
    }

    /* 2.1 */
    function setTradeOne($key, $value) {
        $this->_redis->select(2);

        $this->_redis->rPush($key, json_encode($value));
    }
    function getTradeOne($key, $idx) {
        $jsonStr = (string) NULL;
        $this->_redis->select(2);

        $jsonStr = $this->_redis->lIndex($key, $idx);
        return json_decode($jsonStr, true);
    }
    function getTradeAll($key) {
        $this->_redis->select(2);

        return $this->_redis->lRange($key, 0, -1);
    }
    function getTradeTimes($key) {
        $this->_redis->select(2);

        return $this->_redis->lLen($key);
    }

    /* 2.2 */
    function setTradeStartup($field, $value) {
        $this->_redis->select(2);

        $this->_redis->hSet(self::STARTUP, $field, json_encode($value));
    }

    function hExistsTradeStartup($field) {
        $this->_redis->select(2);

        return $this->_redis->hExists(self::STARTUP, $field);
    }
    function getTradeStartuphGetAll() {
        $this->_redis->select(2);

        return $this->_redis->hGetAll(self::STARTUP);
    }
}
?>
