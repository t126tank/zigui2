# API
## TopN2Manager
  - curTopN : List;
  - oldTopN : List;

  + updateTopN2(List);
  + deleteOldTopN1()

## TradewallManager
  - 

# Structures
## Map<id, Map<pair, state>> - curTopN
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

## Map<id, Map<pair, state>> - oldTopN
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

## Map<timestamp, List<tradeInfo>> - All trade information

## Object - tradeInfo
```
[
    {
        "id": "id1",
        "pair": "usd/jpy",
        "state": "sell",
        "price": 110.34,
        "pl": -99999
    },
    {
        "id": "id1",
        "pair": "usd/eur",
        "state": "sell",
        "price": 0.92348,
        "pl": -99999
    },
    {
        "id": "id2",
        "pair": "usd/jpy",
        "state": "buy",
        "price": 110.34,
        "pl": 1.23
    },
    {
        "id": "id3",
        "pair": "usd/jpy",
        "state": "sell",
        "price": 110.34,
        "pl": 1.23
    }
]
```


・List - pairsFilter
```
["usd/jpy", "usd/eur", "usd/gbp"]
```

# 主处理
## 初次处理
 * 初始化  
   prevTts = -1  
   currTts = time()

 * 获得 currTts时的List<TradeInfo> - by crawler
 * 插入 map<currTts, List<tradeInfo>> - in redis
 * 过滤 tradeInfo->id 在 curTopN
   * id-pair 既存在 - 更新 curTopN 中 对应 id-pair 的 state (buy/sell/closed [tradeInfo->pl ！= -99999])
   * id-pair 不存在 - 插入 curTopN 中 对应 id-pair 的 state (buy/sell [tradeInfo->pl == -99999])
 * 过滤 tradeInfo->id 在 oldTopN 并且 tradeInfo->pl != -99999 ("closed")
   * 删除 oldTopN 中对应的 id-pair
 * pairsFilter 过滤
 * POST 发布
 * 更新 Tts
   prevTts = currTts


## 第X+1次Tts处理
 * 初始化  
  prevTts = X  
  currTts = X+1 -> time()

 * 获得currTts时的List<TradeInfo> - by crawler
 * 获得prevTts时的List<TradeInfo> - from redis
 * 比较此二List
   * 无重叠 - crawler 展开至 同 prevTts时的List<TradeInfo>产生重叠
   * 有重叠
     * 有新tradeinfo - 插入map<currTts, List<tradeInfo>>
     * 无新tradeinfo - 终止本次发布
 * 过滤tradeInfo->id 在 curTopN 并且 tradeInfo->pl == -99999 (NOT "closed")
   * 插入/更新 curTopN 中 对应 id-pair 的 state (buy, sell, closed[tradeInfo->pl != -99999])
 * 过滤tradeInfo->id 在 oldTopN 并且 tradeInfo->pl != -99999 ("closed")
   * 删除 oldTopN 中对应的 id-pair
 * pairsFilter过滤
 * POST 发布
 * 更新 Tts
   prevTts = currTts

# 缩写
 * Tts - Trade Timestamp

