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
    private $_startupAtmOption = NULL;
    private $_lastTradeNode  = NULL;
    private $_firstTradeNode = NULL;

    public function __construct($id, $conf, $dao) {
        $this->_startupId = $id;
        $this->_startupConf = $conf;
        $this->_dao = $dao;

        $v = mb_split(":", $this->_startupId);
        $this->_userId = $v[0];
        $this->_startupTimestamp = intval($v[1]);
        /* 1.1 */
        $startupHistoryNode = $this->_dao->getMarketHistoryOne($this->_startupTimestamp);
        $this->_startupAtmOption = array_filter($startupHistoryNode['options'], "atm");
        /* 2.1 */
        $this->_firstTradeNode = $this->_dao->getTradeOne($this->_startupId,  0);
        $this->_lastTradeNode  = $this->_dao->getTradeOne($this->_startupId, -1);
    }

    public function update(AbstractSubject $subject) {
        $newTimestamp = $subject->getFavorites();
        writeln('*** IN PATTERN OBSERVER - NEW PATTERN GOSSIP ALERT*');
        writeln(' userId(int): '. $this->_userId);
        writeln(' new timestamp(int): '. $newTimestamp);

        /* 1.1 */
        $newHistoryNode = $this->_dao->getMarketHistoryOne($newTimestamp);
        foreach ($newHistoryNode['options'] as $obj) {
            print_r($obj);
        }

        writeln('*** IN PATTERN OBSERVER - PATTERN GOSSIP ALERT OVER*');
    }

    /*
    private function get() {
    }
    private function onTrading() {
        // 1.1
        $historyNode = $dao->getMarketHistoryOne($marketLastTimestamp);

        $atmOption = array_filter($historyNode['options'], "atm");
        $hedgePair = $historyNode['hedges'][$hedgeType];
        $bullPrice = $hedgePair['bull']['price'];
        $bearPrice = $hedgePair['bear']['price'];
        $bullQty   = round($unit / $bullPrice, 0);
        $bearQty   = round($bullPrice/$bearPrice*$bullQty, 0);

        $tradeNode = array(
        'state'=> "OPEN", // define as CONST or Enum
        'timestamp'=> $marketLastTimestamp,
        'bullQty'=> $bullQty,
        'bullPrice'=> $bullPrice,
        'bullVol'=> 0,
        'bearQty'=>$bearQty,
        'bearPrice'=>$bearPrice,
        'bearVol'=>0,
        'cash'=>0
        );

        // $dao->setTradeOne($this->_startId, $tradeNode);
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
        /* Attach each Observer */
        $patternGossipFan = new PatternObserver($key, $v, $dao);
        $patternGossiper->attach($patternGossipFan);
        $patternGossipFanArr[] = $patternGossipFan;
    }
}
var_dump($startupArr); // debug

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

  $tradeDelta = 0.1234;
  $unit = 1200000;
  $hedgeType = "SC_BP";
  $visible = true;

  /* 2.2 - startup */
  $startupNode = array (
    'tradeDelta'=> $tradeDelta,
    'unit'=> $unit,
    'hedgeType'=> $hedgeType,
    'visible'=>$visible
  );
  //$dao->setTradeStartup($key, $startupNode);


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

writeln('END TESTING OBSERVER PATTERN');

?>

