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

class PatternObserver extends AbstractObserver {
    public function __construct() {
    }
    public function update(AbstractSubject $subject) {
      writeln('*IN PATTERN OBSERVER - NEW PATTERN GOSSIP ALERT*');
      writeln(' new favorite patterns: '.$subject->getFavorites());
      writeln('*IN PATTERN OBSERVER - PATTERN GOSSIP ALERT OVER*');      
    }
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



/* Filter */
function atm($var) {
    return ($var['atm'] && true);
}

  writeln('BEGIN TESTING OBSERVER PATTERN');
  writeln('');

  $dao = new RedisDAO();

  $marketLastTimestamp = $dao->getMarketLastTimestamp();
  $userId = "aaa";
  /* Create Key for trading OPEN */
  $key = $userId . ":" . $marketLastTimestamp; // Or AS filed in HashMap
  writeln($key);

  /* IF FILED Exists, EXIT */
  if ($dao->hExistsTradeStartup($key)) {
    echo 'Exists FIELD of '.$key.' in HashMap of "startup"';
    unset($dao);
    exit();
  }

  $tradeDelta = 0.1234;
  $unit = 1200000;
  $hedgeType = "SC_BP";
  $visible = true;

  /* 2.2 - startup */
  $startupNode = array(
    'tradeDelta'=> $tradeDelta,
    'unit'=> $unit,
    'hedgeType'=> $hedgeType,
    'visible'=>$visible
  );
  $dao->setTradeStartup($key, $startupNode);

  /* 2.1 - trade list */
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
    'bullVol'=> $bullQty,
    'bearQty'=>$bearQty,
    'bearPrice'=>$bearPrice,
    'bearVol'=>$bearQty,
    'cash'=>0
  );
  $dao->setTradeOne($key, $tradeNode);

  $patternGossiper = new PatternSubject();
  $patternGossipFan = new PatternObserver();
  $patternGossiper->attach($patternGossipFan);
  $patternGossiper->updateFavorites('abstract factory, decorator, visitor');
  $patternGossiper->updateFavorites('abstract factory, observer, decorator');
  $patternGossiper->detach($patternGossipFan);
  $patternGossiper->updateFavorites('abstract factory, observer, paisley');

  writeln('END TESTING OBSERVER PATTERN');
  unset($dao);

?>

