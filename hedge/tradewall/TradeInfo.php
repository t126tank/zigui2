<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/TradeUtils.php';

class TradeInfo implements JsonSerializable {
  const DETAILS = "https://japan.zulutrade.com/trader/";
  private $_id = NULL;
  private $_tid = NULL;
  private $_pair = NULL;
  private $_price = 0.0;
  private $_pl = 0.0;
  private $_op = NULL;
  private $_state = NULL;
  private $_ts = NULL;
  private $_details = NULL;

  public function __construct($info) {
    $this->_id = trim($info['id']);
    $this->_tid = trim($info['tid']);
    $this->_pair = strtoupper(trim($info['pair']));
    $this->_price = $info['price'];
    $this->_pl = $info['pl'];
    $this->_op = strcasecmp(trim($info['op']), TradeOpEnum::BUY) == 0? TradeOpEnum::BUY: TradeOpEnum::SELL;
    $this->_state = strcasecmp(trim($info['state']), TradeStateEnum::OPEN) == 0? TradeStateEnum::OPEN: TradeStateEnum::CLOSED;
    $this->_op = ($this->_state == TradeStateEnum::OPEN)? $this->_op: TradeOpEnum::opReverse($this->_op); // Close 时,翻转仓类型
    $this->_ts = new DateTime();
    $this->_ts->setTimeZone(new DateTimeZone('Asia/Tokyo'));
    $this->_details = self::DETAILS . $this->_id;
  }

  // @Impl JsonSerializable::jsonSerialize()
  public function jsonSerialize() {
    return [
      'id' => $this->_id,
      'details' => $this->_details,
      'tid' => $this->_tid,
      'pair' => $this->_pair,
      'price' => $this->_price,
      'pl' => $this->_pl,
      'op' => $this->_op,
      'state' => $this->_state,
      'ts' => $this->_ts->format(DateTime::ISO8601)
    ];
  }

  public function equals(TradeInfo $info) {
    return ($this->_tid == $info->getTid()) && ($this->_op == $info->getOp());
  }

  public function __destruct() {
    unset($this->_ts);
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
