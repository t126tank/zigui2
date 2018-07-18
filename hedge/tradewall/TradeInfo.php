<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/TradeUtils.php';

class TradeInfo {
  private $_id = NULL;
  private $_tid = NULL;
  private $_pair = NULL;
  private $_price = 0.0;
  private $_pl = 0.0;
  private $_op = NULL;
  private $_state = NULL;
  private $_ts = 0;  // TODO: which timestamp? order or system

  public function __construct($info) {
    $this->_id = trim($info['id']);
    $this->_tid = trim($info['tid']);
    $this->_pair = strtoupper(trim($info['pair']));
    $this->_price = $info['price'];
    $this->_pl = $info['pl'];
    $this->_op = strcasecmp(trim($info['op']), TradeOpEnum::BUY) == 0? TradeOpEnum::BUY: TradeOpEnum::SELL;
    $this->_state = strcasecmp(trim($info['state']), TradeStateEnum::OPEN) == 0? TradeStateEnum::OPEN: TradeStateEnum::CLOSED;
    // $this->_ts = $info['ts'];
    // $this->_ts = time();
  }

  public function equals(TradeInfo $info) {
    return ($this->_tid == $info->getTid()) && ($this->_op == $info->getOp())
  }

  public function __destruct() {
    // unset($this->_op);
    // unset($this->_state);
  }

  public function getId() {
    return $this->_id;
  }

  public function getTid() {
    return $this->_tid;
  }

  public function getPair() {
    return $this->_pair;
  }

  public function getPrice() {
    return $this->_price;
  }

  public function getPl() {
    return $this->_pl;
  }

  public function getOp() {
    return $this->_op;
  }

  public function getState() {
    return $this->_state;
  }
}
?>
