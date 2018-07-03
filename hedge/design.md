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
   prevTts = -1  
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

## 第X+1次
1. 获得 curTopN <id> List - by crawler
1. 获得 第X次的 curTopN Map
1. 比较 curTopN <id> List 和 curTopN Map
   * id 同时存在 - curTopN Map 及 oldTopN 均无需更新
   * id 只存在于 curTopN <id> List
     * id 亦不存在于 oldTopN Map，向 curTopN Map 插入 id 及对应的 status Map 设空；oldTopN Map 无更新
     * id 也存在于 oldTopN Map，从 oldTopN Map 转移该 id 至 curTopN Map
   * id 只存在于 curTopN Map - 从 curTopN Map 转移该 id 至 oldTopN Map (buy <and> sell stacks 不为 EMPTY)


# 缩写
 * Tts - Trade Timestamp
