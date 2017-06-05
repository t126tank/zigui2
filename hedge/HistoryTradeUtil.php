<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);
require_once __DIR__ . '/RedisDao.php';

/* Filter */
function atm($var) {
    return ($var['atm'] && true);
}

class HistoryTradeUtil {
    private $_startupId = 0;
    private $_dao = NULL;

    private $_userId = '';
    private $_startupTimestamp = 0;
    private $_startupAtmCall = NULL;
    private $_startupAtmPut  = NULL;
    const CALL = 'call';
    const PUT  = 'put';
    const BULL = 'bull';
    const BEAR = 'bear';
    const OPTIONS = 'options';
    const HEDGES  = 'hedges';

    public function __construct($id, $dao) {
        $this->_startupId = $id;
        $this->_dao = $dao;

        $v = mb_split(":", $this->_startupId);
        $this->_userId = $v[0];
        $this->_startupTimestamp = intval($v[1]);
        /* 1.1 */
        $startupHistoryNode = $this->_dao->getMarketHistoryOne($this->_startupTimestamp);
        $startupAtmOptions = array_filter($startupHistoryNode[self::OPTIONS], "atm");
        $this->_startupAtmCall = $this->array_find_opttype(self::CALL, $startupAtmOptions);
        $this->_startupAtmPut  = $this->array_find_opttype(self::PUT,  $startupAtmOptions);
   }

    public function getHistoryCall($ts) {
        $rtn = $this->_startupAtmCall;
        if ($ts != $this->_startupTimestamp) {
            $historyOne = $this->_dao->getMarketHistoryOne($ts);
            $rtn = $this->array_find_opt(self::CALL, $historyOne[self::OPTIONS]);
        }
        return $rtn;
    }

    public function getHistoryPut($ts) {
        $rtn = $this->_startupAtmPut;
        if ($ts != $this->_startupTimestamp) {
            $historyOne = $this->_dao->getMarketHistoryOne($ts);
            $rtn = $this->array_find_opt(self::PUT,  $historyOne[self::OPTIONS]);
        }
        return $rtn;
    }
    public function getHistoryBull($ts) {
        $historyOne = $this->_dao->getMarketHistoryOne($ts);
        return $historyOne[self::HEDGES][self::BULL];
    }
    public function getHistoryBear($ts) {
        $historyOne = $this->_dao->getMarketHistoryOne($ts);
        return $historyOne[self::HEDGES][self::BEAR];
    }
    private function array_find_opttype($needle, $haystack) {
       foreach ($haystack as $item) {
          if (strpos($item['type'], $needle) !== FALSE) { // strcmp
             return $item;
             break;
          }
       }
    }

    private function array_find_opt($needle, $haystack) {
        $option = strcmp($needle, self::CALL) == 0?
                    $this->_startupAtmCall:
                    $this->_startupAtmPut;

        foreach ($haystack as $item) {
            if (strcmp($item['expire'], $option['expire']) == 0 &&
                $item['k'] == $option['k'] &&
                strcmp($item['type'], $needle) == 0) {
                return $item;
                break;
            }
        }
    }
}
?>
