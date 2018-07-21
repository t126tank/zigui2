<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/TradeUtils.php';
require_once __DIR__ . '/TradeInfo.php';

/*
 *  Singleton classes
*/
class TopN2Mgr {
  private $_curTopN = NULL;
  private $_oldTopN = NULL;
  private $_dao = NULL;
  // _mgr instance
  private static $_mgr = NULL;

  private function __construct() {
    $this->_dao = new RedisDao();
  }

  function __destruct() {
    unset($this->_curTopN);
    unset($this->_curTopN);
    unset($this->_dao);
  }

  static function getMgr() {
    if (NULL == self::$_mgr) {
      self::$_mgr = new TopN2Mgr();
    }
    return self::$_mgr;
  }

  function updateTopN2() {
    // 从网页或 WebAPI 获取最新排行榜 - curTopN <id> List
    $ids = TradeUtils::getRank(10);

    $newTopVec = new \Ds\Vector();
    $newTopVec->push(...$ids);

    // 初次处理
    if ($this->_dao->getPrevTimestamp() == 0) {
      // 准备新的 TopN
      $this->_curTopN = new \Ds\Map();
      $this->_oldTopN = new \Ds\Map();
    } else {
      // 从 Redis 取得 TopN2
      $this->_curTopN = $this->_dao->getCurTopN();
      $this->_oldTopN = $this->_dao->getOldTopN();
    }

    // 比较 curTopN <id> List 和 curTopN Map
    foreach ($newTopVec as $id) {
      if (!$this->_curTopN->hasKey($id)) {
        if (!$this->_oldTopN->hasKey($id)) {
          // 为新的 id 分配 status of Map<pair, state>
          $status = new \Ds\Map();
          $this->_curTopN->put($id, $status);
        } else {
          // 从 oldTopN Map 转移该 id 至 curTopN Map
          $this->_curTopN->put($id, new \Ds\Map($this->_oldTopN->get($id)));
          $this->_oldTopN->remove($id);
        }
      }
    }

    // id 只存在于 curTopN Map - Map<id, Map<pair, TradeStacks>>
    foreach ($this->_curTopN as $k => $v) {  // TODO: &$v ?
      // 从 curTopN Map 转移该 id 至 oldTopN Map (buy <and> sell stacks 不为 EMPTY)
      if ($newTopVec->find($k) !== true) {
        $v = $v->filter(function($kk, $vv) {
          return !$this->isStacksBothEmpty($vv);
        });

        if (!$v->isEmpty()) {  // Map<pair, TradeStacks>
          $val = new \Ds\Map($v);
          $this->_oldTopN->put($k, $val);
        }
        $this->_curTopN->remove($k);
      }
    }
  }

  public function saveTopN2() {
    $this->_dao->setCurTopN($this->_curTopN);
    $this->_dao->setOldTopN($this->_oldTopN);
  }

  public function filterTradeInfo(TradeInfo $info) {
    $rtn = false;

    // 使用 curTopN Map 过滤
    if ($this->_curTopN->hasKey($info->getId())) {
      $status = $this->_curTopN->get($info->getId()); // Map<pair, TradeStacks>
      // 只压栈 open
      if ($info->getState() == TradeStateEnum::OPEN) {
        // 当前 pair 不存在
        if (!$status->hasKey($info->getPair())) {
          $status->put($info->getPair(), array(
              TradeOpEnum::BUY  => new \Ds\Stack(),
              TradeOpEnum::SELL => new \Ds\Stack()
          ));
        }
        $status->get($info->getPair())[$info->getOp()]->push($info->getPrice());
        $rtn = true;
      } else if ($info->getState() == TradeStateEnum::CLOSED && $status->hasKey($info->getPair())) {
        // close - sell -> to pop buy::stack; buy -> to pop sell::stack
        $toClz = self::opReverse($info->getOp());

        // 相应 open 栈不为空则可以 pop()
        if (!$status->get($info->getPair())[$toClz]->isEmpty()) {
          $status->get($info->getPair())[$toClz]->pop();
          $rtn = true;
        }
      }
    }

    // 使用 oldTopN Map 过滤 - 只close 不open
    if ($info->getState() == TradeStateEnum::CLOSED && $this->_oldTopN->hasKey($info->getId())) {
      $status = $this->_oldTopN->get($info->getId()); // Map<pair, TradeStacks>
      if ($status->hasKey($info->getPair())) {
        $stacks = $status->get($info->getPair());

        // close - sell -> to pop buy::stack; buy -> to pop sell::stack
        $toClz = self::opReverse($info->getOp());
        if (!$stacks[$toClz]->isEmpty()) {
          $stacks[$toClz]->pop();
          $rtn = true;
        }
        // 若 id - pair 的 sell <and> buy 的 stacks 均为 EMPTY，删除 oldTopN 中 id 对应的 pair
        if (isStacksBothEmpty($stacks))
          $status->remove($info->getPair());

        // 若 id 的 status (Map) 为 EMPTY, 删除 oldTopN 中对应的 id
        if ($status->isEmpty())
          $this->_oldTopN->remove($info->getId());
      }
    }

    return $rtn;
  }

  private function isStacksBothEmpty(\Ds\Stack $stacks) {
    return $stacks[TradeOpEnum::BUY]->isEmpty() && $stacks[TradeOpEnum::SELL]->isEmpty();
  }

  private function opReverse(TradeOpEnum $op) {
    return $op == TradeOpEnum::BUY? TradeOpEnum::SELL: TradeOpEnum::BUY;
  }
}
?>
