// https://sourcemaking.com/design_patterns/observer/php
<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';

abstract class AbstractObserver {
    abstract function update(AbstractSubject $subject_in);
}

abstract class AbstractSubject {
    abstract function attach(AbstractObserver $observer_in);
    abstract function detach(AbstractObserver $observer_in);
    abstract function notify();
}

function writeln($line_in) {
    echo $line_in."<br/>";
}

/* Filter */
function atm($var) {
    return ($var['atm'] && true);
}

class PatternObserver extends AbstractObserver {
    private $_startupId = 0;
    private $_startupConf = NULL;
    private $_dao = NULL;

    private $_userId = '';
    private $_startupTimestamp = 0;
    private $_startupAtmCall = NULL;
    private $_startupAtmPut  = NULL;
    private $_lastTradeNode  = NULL;
    private $_firstTradeNode = NULL;
    const CALL = 'call';
    const PUT  = 'put';

    public function __construct($id, $conf, $dao) {
        $this->_startupId = $id;
        $this->_startupConf = $conf;
        $this->_dao = $dao;

        $v = mb_split(":", $this->_startupId);
        $this->_userId = $v[0];
        $this->_startupTimestamp = intval($v[1]);
        /* 1.1 */
        $startupHistoryNode = $this->_dao->getMarketHistoryOne($this->_startupTimestamp);
        $startupAtmOptions = array_filter($startupHistoryNode['options'], "atm");
        $this->_startupAtmCall = $this->array_find_opttype(self::CALL, $startupAtmOptions);
        $this->_startupAtmPut  = $this->array_find_opttype(self::PUT,  $startupAtmOptions);
        /* 2.1 */
        $this->_firstTradeNode = $this->_dao->getTradeOne($this->_startupId,  0);
        $this->_lastTradeNode  = $this->_dao->getTradeOne($this->_startupId, -1);
    }

    public function update(AbstractSubject $subject) {
        $newTimestamp = $subject->getFavorites();

        writeln('*** IN PATTERN OBSERVER - NEW PATTERN GOSSIP ALERT*');
        writeln(' userId(int): '. $this->_userId);
        writeln(' last timestamp(int): '. $newTimestamp);
        writeln(' trade option delta: '. $this->_startupConf['tradeDelta']);
        writeln(' startup trade timestamp(int): '. $this->_firstTradeNode['timestamp']);

        $this->onTradingDiffDelta($newTimestamp);
        
        //foreach ($newHistoryNode['options'] as $obj) {
            // print_r($obj);
        //}

        writeln('*** IN PATTERN OBSERVER - PATTERN GOSSIP ALERT OVER*');
    }

    private function onTradingDiffDelta($nts) {
        /* 1.1 */
        $lastTradeHistoryNode = $this->_dao->getMarketHistoryOne($this->_lastTradeNode['timestamp']);
        $lastTradeCall = $this->array_find_opt(self::CALL, $lastTradeHistoryNode['options']);
        $lastTradePut  = $this->array_find_opt(self::PUT,  $lastTradeHistoryNode['options']);

        $newHistoryNode = $this->_dao->getMarketHistoryOne($nts);
        $newHistoryCall = $this->array_find_opt(self::CALL, $newHistoryNode['options']);
        // prevent invalid delta
        $newHistoryCall = is_null($newHistoryCall)? $lastTradeCall: $newHistoryCall;

        $newHistoryPut  = $this->array_find_opt(self::PUT,  $newHistoryNode['options']);
        // prevent invalid delta
        $newHistoryPut = is_null($newHistoryPut)? $lastTradePut: $newHistoryPut;

        $diffDeltaCall = $newHistoryCall['delta'] - $lastTradeCall['delta'];
        $diffDeltaPut  = $newHistoryPut['delta']  - $lastTradePut['delta'];

        writeln(' diff option delta (call): '. $diffDeltaCall);
        writeln(' diff option delta (put): ' . $diffDeltaPut);
        if (abs($diffDeltaCall) < $this->_startupConf['tradeDelta'] ||
            abs($diffDeltaPut)  < $this->_startupConf['tradeDelta']) {
            writeln(' XXX NOT TRADING XXX ');
            return;
        }
        writeln(' OOO Let\'s TRADING OOO ');

        $hedgePair = $newHistoryNode['hedges'];
        $bullPrice = $hedgePair['bull']['price'];
        $bearPrice = $hedgePair['bear']['price'];
        $bullVol   = round($this->_startupConf['volBullRatio'] * abs($newHistoryCall['delta']), 0);
        $bearVol   = round($this->_startupConf['volBearRatio'] * abs($newHistoryPut['delta']),  0);
        $bullQty   = $bullVol - $this->_lastTradeNode['bullVol'];
        $bearQty   = $bearVol - $this->_lastTradeNode['bearVol'];
        $cash      = (-1)*($bullPrice*$bullQty + $bearPrice*$bearQty) +
                     $this->_lastTradeNode['cash'];

        $tradeNode = array(
            'state'=> "TRADING", // define as CONST or Enum
            'timestamp'=> $nts,
            'bullQty'=> $bullQty,
            'bullPrice'=> $bullPrice,
            'bullVol'=> $bullVol,
            'bearQty'=>$bearQty,
            'bearPrice'=>$bearPrice,
            'bearVol'=>$bearVol,
            'cash'=>$cash
        );

        $this->_dao->setTradeOne($this->_startupId, $tradeNode);
        $initPos = $this->_firstTradeNode['bullPrice']*$this->_firstTradeNode['bullVol'] +
                   $this->_firstTradeNode['bearPrice']*$this->_firstTradeNode['bearVol'];
        $newPos  = $tradeNode['bullPrice']*$tradeNode['bullVol'] +
                   $tradeNode['bearPrice']*$tradeNode['bearVol'] +
                   $tradeNode['cash'];
        writeln(' !!! We earned : '. ($newPos/$initPos - 1));
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
        $rtn = NULL;
        $option = strcmp($needle, self::CALL) == 0?
                    $this->_startupAtmCall:
                    $this->_startupAtmPut;

        foreach ($haystack as $item) {
            if (strcmp($item['expire'], $option['expire']) == 0 &&
                $item['k'] == $option['k'] &&
                strcmp($item['type'], $needle) == 0) {
                $rtn = $item;
                break;
            }
        }
        return $rtn;
    }

    /*
    private function get() {
    }
    private function onTrading() {
        // 1.1
        $historyNode = $dao->getMarketHistoryOne($marketLastTimestamp);

        $atmOption = array_filter($historyNode['options'], "atm");
        
    }
    */
}


class PatternSubject extends AbstractSubject {
    private $favoritePatterns = NULL;
    private $observers = array();

    function __construct() {
    }

    function attach(AbstractObserver $observer_in) {
      //could also use array_push($this->observers, $observer_in);
      $this->observers[] = $observer_in;
    }
    function detach(AbstractObserver $observer_in) {
      //$key = array_search($observer_in, $this->observers);
      foreach($this->observers as $okey => $oval) {
        if ($oval == $observer_in) { 
          unset($this->observers[$okey]);
        }
      }
    }
    function notify() {
      foreach($this->observers as $obs) {
        $obs->update($this);
      }
    }
    function updateFavorites($newFavorites) {
      $this->favorites = $newFavorites;
      $this->notify();
    }
    function getFavorites() {
      return $this->favorites;
    }
}


$dao = new RedisDAO();

/* Get all visible FIELDs and Values from HashMap startup */
$startupObj = (object) $dao->getTradeStartuphGetAll();  

/* Register each startup as Observer */
$patternGossiper = new PatternSubject();
$startupArr = array(); // debug
$patternGossipFanArr = array();

foreach ($startupObj as $key => $value) {
    $v = json_decode($value, true); // $value is encoded in redis
    if ($v['visible']) {
        $startupArr[$key] = $v; // debug

        /* Attach each visible and open/trading Observer */
        $lastTradeNode  = $dao->getTradeOne($key, -1);
        if (strcmp($lastTradeNode['state'], "CLOSE") != 0) {
            $patternGossipFan = new PatternObserver($key, $v, $dao);
            $patternGossiper->attach($patternGossipFan);
            $patternGossipFanArr[] = $patternGossipFan;
        }
    }
}
// var_dump($startupArr); // debug

/* Get last market history record and update */
$marketLastTimestamp = $dao->getMarketLastTimestamp();
$patternGossiper->updateFavorites($marketLastTimestamp);

  writeln('BEGIN TESTING OBSERVER PATTERN');
  writeln('');


  $marketLastTimestamp = $dao->getMarketLastTimestamp();
  $userId = "aaa";
  /* Create Key for trading OPEN */
  $key = $userId . ":" . $marketLastTimestamp; // Or AS filed in HashMap
  writeln($key);

  // $patternGossiper = new PatternSubject();
  // $patternGossipFan = new PatternObserver();
  // $patternGossiper->attach($patternGossipFan);
  // $patternGossiper->updateFavorites('abstract factory, decorator, visitor');
  // $patternGossiper->updateFavorites('abstract factory, observer, decorator');
  // $patternGossiper->detach($patternGossipFan);
  // $patternGossiper->updateFavorites('abstract factory, observer, paisley');

/* Detach each Observer */
foreach ($patternGossipFanArr as $fan) {
    $patternGossiper->detach($fan);
}

unset($dao);
writeln('END TESTING OBSERVER PATTERN');

?>

