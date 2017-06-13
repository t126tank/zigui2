<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';

$req = array(
         'tradeDelta' =>0.05678,
         'investAmnt' =>24
);
if (!isset($_GET['tradeDelta']) || !isset($_GET['investAmnt'])) {
    echo "_POST problem";
}
$req['tradeDelta'] = abs(doubleval($_GET['tradeDelta']));
$req['investAmnt'] = abs(intval($_GET['investAmnt'])*5000); // 10 thousand for hedge pair

if (!is_numeric($req['tradeDelta']) || !is_numeric($req['investAmnt'])) {
    echo "numeric problem";
    exit();
}

abstract class AbstractObserver {
    abstract function update(AbstractSubject $subject_in);
}

abstract class AbstractSubject {
    abstract function attach(AbstractObserver $observer_in);
    abstract function detach(AbstractObserver $observer_in);
    abstract function notify();
}

function writeln($line_in) {
    // echo $line_in."<br/>";
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

function array_find_opttype($needle, $haystack) {
   foreach ($haystack as $item) {
      if (strcmp($item['type'], $needle) == 0) {
         return $item;
         break;
      }
   }
}

  writeln('BEGIN TESTING OBSERVER PATTERN');
  writeln('');

  $dao = new RedisDAO();

  $marketLastTimestamp = $dao->getMarketLastTimestamp();
  $userId = "aaa";
  /* Create Key for trading OPEN */
  $key = $userId . ":" . $marketLastTimestamp; // Or AS filed in HashMap
  echo "My NEW positon: " . $key;

  /* IF FILED Exists, EXIT */
  if ($dao->hExistsTradeStartup($key)) {
    echo 'Exists FIELD of '.$key.' in HashMap of "startup"';
    unset($dao);
    exit();
  }

  /* 2.1 - trade list */
  $historyNode = $dao->getMarketHistoryOne($marketLastTimestamp);

  $atmOptions = array_filter($historyNode['options'], "atm");

  $unit = $req['investAmnt'];
  $bullPrice = $historyNode['hedges']['bull']['price'];
  $bearPrice = $historyNode['hedges']['bear']['price'];
  $bullQty   = round($unit / $bullPrice, 0);
  $bearQty   = round($unit / $bearPrice, 0);

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

  /* 2.2 - startup */
  $tradeDelta = $req['tradeDelta'];
  $visible = true;

  $call = array_find_opttype("call", $atmOptions);
  $put  = array_find_opttype("put",  $atmOptions);

  $startupNode = array(
    'tradeDelta'=> abs($tradeDelta),
    'unit'=> $unit,
    'volBullRatio' => $unit / $bullPrice / abs($call['delta']),
    'volBearRatio' => $unit / $bearPrice / abs($put['delta']),
    'visible'=>$visible
  );
  $dao->setTradeStartup($key, $startupNode);


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

