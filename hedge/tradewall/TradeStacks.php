<?php

class TradeStateEnum extends SplEnum {
  const __default = self::OPEN;

  const OPEN   = "open";
  const CLOSED = "closed";
}

class TradeOpEnum extends SplEnum {
  const __default = self::BUY;

  const BUY  = "buy";
  const SELL = "sell";
}

class TradeStacks {
  private $_stacks = NULL;

  public function __construct() {
    $this->_stacks = array(
        TradeOpEnum::BUY  => new \Ds\Stack(),
        TradeOpEnum::SELL => new \Ds\Stack()
    );
  }

  public function __destruct() {
    unset($this->_stacks[TradeOpEnum::BUY]);
    unset($this->_stacks[TradeOpEnum::SELL]);
    unset($this->_stacks);
  }

  public function isStacksBothEmpty() {
    return $this->_stacks[TradeOpEnum::BUY]->isEmpty() && $this->_stacks[TradeOpEnum::SELL]->isEmpty();
  }
}
?>
