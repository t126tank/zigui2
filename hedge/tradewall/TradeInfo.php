<?php

class TradeStateEnum extends SplEnum {
  const __default = self::OPEN;

  const OPEN = "open";
  const CLOSED = "closed";
}

class TradeOpEnum extends SplEnum {
  const __default = self::BUY;

  const BUY = "buy";
  const SELL = "sell";
}

class TradeInfo {
  private $_id = NULL;
  private $_pair = NULL;
  private $_price = 0.0;
  private $_pl = 0.0;
  private $_op = NULL;
  private $_state = NULL;
  private $_ts = 0;  // TODO: which timestamp? order or system

  public function __construct($info) {
    $this->_id = trim($info["id"]);
    $this->_pair = strtoupper(trim($info["pair"]));
    $this->_price = $info["price"];
    $this->_pl = $info["pl"];
    $this->_op = strcasecmp(trim($info["op"]), TradeOpEnum::BUY) == 0? new TradeOpEnum(TradeOpEum::BUY): new TradeOpEnum(TradeOpEnum::SELL);
    $this->_state = $info["pl"] != -99999? new TradeStateEnum(TradeStateEnum::OPEN): new TradeStateEnum(TradeStateEnum::CLOSED);
    $this->_ts = $info["ts"];
  }

  public function __destruct() {
    unset($this->_op);
    unset($this->_state);
  }
}
?>
