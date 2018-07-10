# API
## TopN2Manager
  - curTopN : Map;
  - oldTopN : Map;

  + updateTopN2(List);
  + deleteOldTopN1()

## TradewallManager
  - 

# Structures
## Map<id, Map<pair, state>> - curTopN (※state → sellStack[] & buyStack[])
```
[
   {
      "id":"id1",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"closed"
         }
      ]
   },
   {
      "id":"id2",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"closed"
         }
      ]
   },
   {
      "id":"id3",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"closed"
         }
      ]
   },
   {
      "id":"id4",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"closed"
         }
      ]
   }
]
```

## Map<id, Map<pair, state>> - oldTopN (※state → sellStack[] & buyStack[])
```
[
   {
      "id":"id11",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"buy"
         }
      ]
   },
   {
      "id":"id21",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"sell"
         }
      ]
   },
   {
      "id":"id31",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"buy"
         }
      ]
   },
   {
      "id":"id41",
      "status":[
         {
            "pair":"usd/jpy",
            "state":"sell"
         },
         {
            "pair":"usd/eur",
            "state":"buy"
         },
         {
            "pair":"usd/gbp",
            "state":"sell"
         }
      ]
   }
]
```

## Map<timestamp, List\<TradeInfo>> - All trade information

## Object - TradeInfo
```
[
    {
        "id": "id1",
        "pair": "usd/jpy",
        "state": "sell",  → sellStack.push(110.34) ★
        "price": 110.34,
        "pl": -99999
    },
    {
        "id": "id1",
        "pair": "usd/eur",
        "state": "sell", → sellStack.push(0.92348) ★
        "price": 0.92348,
        "pl": -99999
    },
    {
        "id": "id2",
        "pair": "usd/jpy",
        "state": "buy", → sellStack.pop() ★
        "price": 110.34,
        "pl": 1.23 → "closed" ★
    },
    {
        "id": "id3",
        "pair": "usd/jpy",
        "state": "sell", → buyStack.pop() ★
        "price": 110.34,
        "pl": 1.23 → "closed" ★
    }
]
```


## List - pairsFilter
```
["usd/jpy", "usd/eur", "usd/gbp"]
```

# Tradewall - 主处理
## 初次处理
1. 初始化  
   prevTts = 0  
   currTts = time()

1. 获得 currTts 时的List\<TradeInfo> - by crawler
1. 插入 map<currTts, List\<tradeInfo>> - in redis <serialize()>
1. 过滤 tradeInfo->id 在 curTopN:
   * 插入 curTopN 中 对应 id-pair 的 sell/buy stacks - push(<price>) [tradeInfo->pl == -99999]
   * 忽略 closed [tradeInfo->pl ！= -99999]
1. (※初次处理，不进行) 过滤 tradeInfo->id 在 oldTopN 并且 pair 的 sell <or> buy 的 stack 为 EMPTY 或 pair 不存在
   * 维持 oldTopN 中对应的 id-pair 的 sell <or> buy 的 EMPTY stack 不再更新
     * 若 id - pair 的 sell <and> buy 的 stacks 均为 EMPTY，删除 oldTopN 中 id 对应的 pair
     * 若 id 的 status (Map) 为 EMPTY, 删除 oldTopN 中对应的 id
1. pairsFilter 过滤
1. POST 发布
1. 更新 Tts  
   prevTts = currTts


## 第X+1次Tts处理
1. 初始化  
  prevTts = X  
  currTts = X+1 -> time()

1. 获得 currTts时的List\<TradeInfo> - by crawler
1. 获得 prevTts时的List\<TradeInfo> - from redis <unserialize()>
1. 比较此二 List
   * 无重叠 - crawler 展开至同 prevTts 时的 List\<TradeInfo> 产生重叠
   * 有重叠
     * 有新的 tradeinfo - 新的插入map<currTts, List\<tradeInfo>> - in redis <serialize()>
     * 无新的 tradeinfo - 终止本次发布
1. 过滤新的 tradeInfo->id 在 curTopN:
   * 插入 curTopN 中 对应 id-pair 的 sell/buy stacks - push(<price>) [tradeInfo->pl == -99999]
   * curTopN 中 对应 id-pair 的 sell/buy stacks 不为 EMPTY, closed [tradeInfo->pl ！= -99999] - pop()
   * curTopN 中 对应 id-pair 的 sell/buy stacks 为 EMPTY, 忽略 closed [tradeInfo->pl ！= -99999]
1. 过滤 tradeInfo->id 在 oldTopN 并且 pair 的 sell <or> buy 的 stack 为 EMPTY 或 pair 不存在
   * 维持 oldTopN 中对应的 id-pair 的 sell <or> buy 的 EMPTY stack 不再更新
     * 若 id - pair 的 sell <and> buy 的 stacks 均为 EMPTY，删除 oldTopN 中 id 对应的 pair
     * 若 id 的 status (Map) 为 EMPTY, 删除 oldTopN 中对应的 id
1. pairsFilter过滤
1. POST 发布
1. 更新 Tts  
   prevTts = X+1 -> currTts

# TopN - 主处理
## 初次处理
1. 初始化  
   获得 curTopN <id> List - by crawler  
   从 curTopN <id> List 生成 curTopN Map  
   ※ id 对应的 status(Map) 初始化
1. oldTopN Map 设空
1. 保存 curTopN Map and oldTopN Map - in redis <serialize()>

## 第X+1次
1. 获得 curTopN <id> List - by crawler
1. 获得 第X次的 curTopN Map 及 oldTopN Map - from redis <unserialize()>
1. 比较 curTopN <id> List 和 curTopN Map
   * id 同时存在 - curTopN Map 及 oldTopN 均无需更新
   * id 只存在于 curTopN <id> List
     * id 亦不存在于 oldTopN Map，向 curTopN Map 插入 id 及对应的 status Map 设空；oldTopN Map 无更新
     * id 也存在于 oldTopN Map，从 oldTopN Map 转移该 id 至 curTopN Map
   * id 只存在于 curTopN Map - 从 curTopN Map 转移该 id 至 oldTopN Map (buy <and> sell stacks 不为 EMPTY)

# ZuluRedisDao
## http://redis.shibu.jp/commandreference/
## https://redis.io/commands
## http://sandbox.onlinephpfunctions.com/

```php
/*
 * 1 --- Tradewall
 * 1.1 - Key: ZULU_TRADEWALL_HISTORY
 * 1.2 - Key: ZULU_TRADEWALL_PREV
 * 
 * 2 --- TopN2
 * 2.1 - Key: ZULU_TRADEWALL_TOP: CUR
 * 2.2 - Key: ZULU_TRADEWALL_TOP: OLD
 */
/* 1.1 */
function getHistory($field) {   // timestamp: int
    $this->_redis->select(1);

    $value = $this->_redis->hGet(self::ZULU_TRADEWALL_HISTORY, strval($field));
    return unserialize($value); // \DS\Vector<TradeInfo>
}

function setHistory($field, $value) { // timestamp: int, all signals: \DS\Vector<TradeInfo>
    $this->_redis->select(1);

    $this->_redis->hSet(self::ZULU_TRADEWALL_HISTORY, strval($field), serialize($value));
}

/* 1.2 */
function getPrevTimestamp() {
    $this->_redis->select(1);

    // needs to convert "nil" to 0 if non-exists
    return intval($this->_redis->get(self::ZULU_TRADEWALL_PREV));
}

function setPrevTimestamp($value) {   // timestamp: int
    $this->_redis->select(1);

    $this->_redis->set(self::ZULU_TRADEWALL_PREV, strval($value));
}

/* 2.1 */
function getCurTopN() {   // \DS\Map
    $this->_redis->select(2);

    $value = $this->_redis->hGet(self::ZULU_TRADEWALL_TOP, self::CUR);
    return unserialize($value); // \DS\Map<id, status>
}

function setCurTopN($value) { // \DS\Map<id, status>
    $this->_redis->select(2);

    $this->_redis->hSet(self::ZULU_TRADEWALL_TOP, self::CUR, serialize($value));
}

/* 2.2 */
function getOldTopN() {   // \DS\Map
    $this->_redis->select(2);

    $value = $this->_redis->hGet(self::ZULU_TRADEWALL_TOP, self::OLD);
    return unserialize($value); // \DS\Map<id, status>
}

function setOldTopN($value) { // \DS\Map<id, status>
    $this->_redis->select(2);

    $this->_redis->hSet(self::ZULU_TRADEWALL_TOP, self::OLD, serialize($value));
}

```

# 缩写
 * Tts - Trade Timestamp

# crawler 内容 ($ curl url --no-insecure)
## https://japan.zulutrade.com
```html
<table class="clean signal-providers provider-statistics-minimal" border="0" id="main__ctrl_0__ctrl_1_GvProviders">
    <tr class="solid">
        <th scope="col">交易者</th><th scope="col">获利 (点数)</th><th scope="col">投资回报率</th>
    </tr><tr>
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_0">1<sup>#</sup></span>
                <a href="/trader/334440" target="_self" title="GainsPTWS">GainsPTWS</a>
            </td><td>23,021</td><td>110%</td>
    </tr><tr class="alternating-row">
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_1">2<sup>#</sup></span>
                <a href="/trader/363099" target="_self" title="Allalgar">Allalgar</a>
            </td><td>4,101</td><td>353%</td>
    </tr><tr>
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_2">3<sup>#</sup></span>
                <a href="/trader/317418" target="_self" title="Zlatanic">Zlatanic</a>
            </td><td>284,771</td><td>198%</td>
    </tr><tr class="alternating-row">
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_3">4<sup>#</sup></span>
                <a href="/trader/327595" target="_self" title="Teratornis">Teratornis</a>
            </td><td>2,436</td><td>155%</td>
    </tr><tr>
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_4">5<sup>#</sup></span>
                <a href="/trader/363769" target="_self" title="Torus001">Torus001</a>
            </td><td>3,007</td><td>135%</td>
    </tr><tr class="alternating-row">
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_5">6<sup>#</sup></span>
                <a href="/trader/342249" target="_self" title="rydwaves">rydwaves</a>
            </td><td>19,947</td><td>178%</td>
    </tr><tr>
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_6">7<sup>#</sup></span>
                <a href="/trader/318994" target="_self" title="6SmashFX">6SmashFX</a>
            </td><td>306,103</td><td>215%</td>
    </tr><tr class="alternating-row">
        <td class="trader">
                <span id="main__ctrl_0__ctrl_1_GvProviders_LblRank_7">8<sup>#</sup></span>
                <a href="/trader/369867" target="_self" title="QuantMaker">QuantMaker</a>
            </td><td>1,505</td><td>719%</td>
    </tr>
</table>
```

## https://japan.zulutrade.com/tradewall
```html
TBD
```
