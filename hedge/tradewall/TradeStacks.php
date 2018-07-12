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

class TradeStacks {
  private $_pair = NULL;
  private $_bStack = NULL;  // buy  open stack
  private $_sStack = NULL;  // sell open stack

  public function __construct($pair) {
    $this->_pair = strtoupper(trim($pair));
    $this->_bStack = new \Ds\Stack();
    $this->_sStack = new \Ds\Stack();
  }

  public function __destruct() {
    unset($this->_bStack);
    unset($this->_sStack);
  }

  public function getBstack() {
    return $this->_bStack;
  }

  public function getSstack() {
    return $this->_sStack;
  }

}
?>
