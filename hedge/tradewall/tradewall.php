<?php

//include('../dom/simple_html_dom.php');

$idx = 1;
if (isset($_GET["idx"]) && is_numeric($_GET["idx"])) {
   $tmp = abs(intval($_GET["idx"]));
   $idx = ($tmp == 0)? $idx: ($tmp > 3 ? 3: $tmp);
}

ob_start();

$tradewall = 'https://japan.zulutrade.com/webservices/tradewall.asmx/gettradewallevents?_tsmp=' . time();

$opts = array(
         'http'=>array(
            'method'=>"POST",
            'content'=>json_encode(array(
               'displayClosedTrades'=> true,
               'displayHavingLiveFollowers'=> false,
               'displayOpenTrades'=> true,
               'displayStatusMessages'=> true,
               'minutesAgo'=>	288000000,
               'onlyFollowedByMe'=>	false,
               'pageIndex'=> $idx,
               'pageSize'=> 33,
               'platform'=>"forex",
               'providerName'=>""
            )),
            'header'=>"Host: japan.zulutrade.com\r\n".
                     "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0\r\n".
                     "Accept: application/json, text/javascript, */*; q=0.01\r\n".
                     "Accept-Language: ja,en-US;q=0.7,en;q=0.3\r\n".
                     //"Accept-Encoding: gzip, deflate, br\r\n".
                     "Referer: https://japan.zulutrade.com/tradewall\r\n".
                     "Content-Type: application/json; charset=utf-8\r\n".
                     "X-RequestVerificationToken:MoUvRVqejIsTwO8CmFjfdCJmo_dnS6qGX5uRV4XYec8MGI4Wldi0PwehDizeXylKdHgDFsbnNSGg7BLTU7TgnGPKmck3HTfYzLLWERTvKPlC67izrTPDz5x4QbnnL2YWSC14FA2\r\n".
                     "X-Requested-With: XMLHttpRequest\r\n".
                     //"Content-Length: 230\r\n".
                     //"Connection: keep-alive\r\n".
                     "Cookie: zt_Cult=ja; zt_FPBan=1505877354494.12; _ga=GA1.2.1573027694.1503285357; __qca=P0-1796664665-1503285356946; intercom-id-jlr1fm54=472fca3c-d774-4d25-aa83-3441a6b10eb7; _gid=GA1.2.1855047514.1531573422; zt_Ses=ca2bwuatqhuvgy2byx2wit1d; __RequestVerificationToken=12k9a3nXzityxX0RnW6CAqwgwY7iXbO6oIiTguAD5nHPupcw8itiYcvag8FIOlJvlnCDZV6k4qx96LH2z6VI8ANhyc_bHw-2q3tbmEq7mJ3AGVcLqUkXgRPJbxeHKxW6gcbXWQ2; _hjIncludedInSample=1; zt_Perf=%7B%22SortExpression%22%3A%22Ranking%22%2C%22SortDirection%22%3A%22Ascending%22%2C%22TimeFrame%22%3A10000%7D; _gat=1\r\n"
         )
);

//print_r($opts);
$ctx = stream_context_create($opts);
//$html = file_get_html($tradewall, false, $ctx);
$jsonObj = file_get_contents($tradewall, false, $ctx);
//echo $jsonObj;

$jsonArr = json_decode($jsonObj, true);
$jsonArr = $jsonArr['d'];
//print_r($jsonArr);

$tradwallArr = array();

foreach ($jsonArr as $v) {
   $op = strpos($v['t'], 'BUY') !== false? 'BUY': 'SELL';
   $state = strpos($v['t'], 'PnL') !== false? 'CLOSED': 'OPEN';
   $obj = array(
      'id'=>trim(strval($v['pid'])),
      'tid'=>trim(strval($v['tid'])),
      'pl'=>$v['pnl'],
      'price'=>$v['pr'],
      'op'=>$op,
      'state'=>$state,
      'pair'=>$v['cun']
   );
   $tradwallArr[] = $obj;
}

echo json_encode($tradwallArr, JSON_UNESCAPED_UNICODE);

$length = ob_get_length();

header("Content-Type: application/json; charset=UTF-8");
//header("Content-Type: html/text; charset=UTF-8");
header("Content-Length:".$length."\r\n");
header("Accept-Ranges: bytes"."\r\n");

ob_end_flush();
/*
{
   "d":[
      {
         "__type":"Z.TE",
         "pid":341487,
         "bid":1823501,
         "pn":"Light path",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/341487\" target=\"_blank\"\u003eLight path\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.74224\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） AUD/USD\u003c/span\u003e ポジション開いた。",
         "cc":"RU",
         "cn":"Russia",
         "ta":"2 日",
         "tid":470608446,
         "pt":"300.1531140690094",
         "tc":1,
         "cun":"AUD/USD",
         "pr":0.74224,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":341487,
         "bid":1823501,
         "pn":"Light path",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/341487\" target=\"_blank\"\u003eLight path\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.67669\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） NZD/USD\u003c/span\u003e ポジション開いた。",
         "cc":"RU",
         "cn":"Russia",
         "ta":"2 日",
         "tid":470608445,
         "pt":"300.1531140690090",
         "tc":0,
         "cun":"NZD/USD",
         "pr":0.67669,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":364854,
         "bid":1777098,
         "pn":"RoboFish",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/364854\" target=\"_blank\"\u003eRoboFish\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.88345\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） EUR/GBP\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #66D351;\"\u003e16.9\u003c/span\u003e ピップ。",
         "cc":"IT",
         "cn":"Italy",
         "ta":"2 日",
         "tid":397862822,
         "pt":"300.1531140588426",
         "tc":1,
         "cun":"EUR/GBP",
         "pr":0.88345,
         "pi":16.9,
         "pnl":2.18
      },
      {
         "__type":"Z.TE",
         "pid":359638,
         "bid":1737391,
         "pn":"G500 Baaza",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/359638\" target=\"_blank\"\u003eG500 Baaza\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e131.315\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） EUR/JPY\u003c/span\u003e ポジション開いた。",
         "cc":"ZA",
         "cn":"South Africa",
         "ta":"2 日",
         "tid":470608444,
         "pt":"132.636670733901149093",
         "tc":0,
         "cun":"EUR/JPY",
         "pr":131.315,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":367433,
         "bid":1810994,
         "pn":"Ontechtrade",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/367433\" target=\"_blank\"\u003eOntechtrade\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e1.53769\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） EUR/CAD\u003c/span\u003e ポジション開いた。",
         "cc":"GB",
         "cn":"United Kingdom",
         "ta":"2 日",
         "tid":470607279,
         "pt":"400.1531141260808",
         "tc":0,
         "cun":"EUR/CAD",
         "pr":1.53769,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":330796,
         "bid":1581745,
         "pn":"takfarinas",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/330796\" target=\"_blank\"\u003etakfarinas\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.97694\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） AUD/CAD\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #FF780C;;\"\u003e-19.8\u003c/span\u003e ピップ。",
         "cc":"DZ",
         "cn":"Algeria",
         "ta":"2 日",
         "tid":397862818,
         "pt":"666.1531170449680",
         "tc":1,
         "cun":"AUD/CAD",
         "pr":0.97694,
         "pi":-19.8,
         "pnl":-1.51
      },
      {
         "__type":"Z.TE",
         "pid":373348,
         "bid":1856475,
         "pn":"EAScalping",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/373348\" target=\"_blank\"\u003eEAScalping\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.67814\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） NZD/CHF\u003c/span\u003e ポジション開いた。",
         "cc":"ZA",
         "cn":"South Africa",
         "ta":"2 日",
         "tid":470608442,
         "pt":"400.1531141271372",
         "tc":0,
         "cun":"NZD/CHF",
         "pr":0.67814,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":367542,
         "bid":1804037,
         "pn":"Auto Profit EA",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/367542\" target=\"_blank\"\u003eAuto Profit EA\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e148.64\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） GBP/JPY\u003c/span\u003e ポジション開いた。",
         "cc":"VN",
         "cn":"Vietnam",
         "ta":"2 日",
         "tid":470608440,
         "pt":"400.1531141271356",
         "tc":1,
         "cun":"GBP/JPY",
         "pr":148.64,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":373348,
         "bid":1856475,
         "pn":"EAScalping",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/373348\" target=\"_blank\"\u003eEAScalping\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e148.743\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） GBP/JPY\u003c/span\u003e ポジション開いた。",
         "cc":"ZA",
         "cn":"South Africa",
         "ta":"2 日",
         "tid":470608441,
         "pt":"400.1531141271359",
         "tc":0,
         "cun":"GBP/JPY",
         "pr":148.743,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":365282,
         "bid":1781270,
         "pn":"Runner 6",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/365282\" target=\"_blank\"\u003eRunner 6\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e148.651\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） GBP/JPY\u003c/span\u003e ポジション開いた。",
         "cc":"NG",
         "cn":"Nigeria",
         "ta":"2 日",
         "tid":470607484,
         "pt":"400.1531141262625",
         "tc":1,
         "cun":"GBP/JPY",
         "pr":148.651,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":367433,
         "bid":1810994,
         "pn":"Ontechtrade",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/367433\" target=\"_blank\"\u003eOntechtrade\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e1.09731\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） AUD/NZD\u003c/span\u003e ポジション開いた。",
         "cc":"GB",
         "cn":"United Kingdom",
         "ta":"2 日",
         "tid":470605047,
         "pt":"400.1531141251358",
         "tc":0,
         "cun":"AUD/NZD",
         "pr":1.09731,
         "pi":0,
         "pnl":0
      },
      {
         "__type":"Z.TE",
         "pid":371932,
         "bid":1843144,
         "pn":"Dont Worry In Buffet",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/371932\" target=\"_blank\"\u003eDont Worry In Buffet\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e1.16858\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） EUR/USD\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #FF780C;;\"\u003e-13.5\u003c/span\u003e ピップ。",
         "cc":"UA",
         "cn":"Ukraine",
         "ta":"2 日",
         "tid":397862807,
         "pt":"300.1531140108930",
         "tc":0,
         "cun":"EUR/USD",
         "pr":1.16858,
         "pi":-13.5,
         "pnl":-1.58
      },
      {
         "__type":"Z.TE",
         "pid":365389,
         "bid":1782344,
         "pn":"ZX ACCOUNT 99",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/365389\" target=\"_blank\"\u003eZX ACCOUNT 99\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.88294\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） EUR/GBP\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #66D351;\"\u003e21\u003c/span\u003e ピップ。",
         "cc":"CN",
         "cn":"China",
         "ta":"2 日",
         "tid":397862802,
         "pt":"131.636669981987935648",
         "tc":1,
         "cun":"EUR/GBP",
         "pr":0.88294,
         "pi":21,
         "pnl":278
      },
      {
         "__type":"Z.TE",
         "pid":365389,
         "bid":1782344,
         "pn":"ZX ACCOUNT 99",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/365389\" target=\"_blank\"\u003eZX ACCOUNT 99\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e0.88295\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e売り（SELL） EUR/GBP\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #66D351;\"\u003e20.6\u003c/span\u003e ピップ。",
         "cc":"CN",
         "cn":"China",
         "ta":"2 日",
         "tid":397862800,
         "pt":"131.636669981987935649",
         "tc":1,
         "cun":"EUR/GBP",
         "pr":0.88295,
         "pi":20.6,
         "pnl":272.7
      },
      {
         "__type":"Z.TE",
         "pid":171089,
         "bid":1018316,
         "pn":"YourFxLegend",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/171089\" target=\"_blank\"\u003eYourFxLegend\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e8.8803\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） USD/SEK\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #FF780C;;\"\u003e-396\u003c/span\u003e ピップ。",
         "cc":"LB",
         "cn":"Lebanon",
         "ta":"2 日",
         "tid":397862799,
         "pt":"131.636669981987937085",
         "tc":0,
         "cun":"USD/SEK",
         "pr":8.8803,
         "pi":-396,
         "pnl":-445.81
      },
      {
         "__type":"Z.TE",
         "pid":171089,
         "bid":1018316,
         "pn":"YourFxLegend",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/171089\" target=\"_blank\"\u003eYourFxLegend\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e8.8803\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） USD/SEK\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #FF780C;;\"\u003e-392\u003c/span\u003e ピップ。",
         "cc":"LB",
         "cn":"Lebanon",
         "ta":"2 日",
         "tid":397862798,
         "pt":"131.636669981987937086",
         "tc":0,
         "cun":"USD/SEK",
         "pr":8.8803,
         "pi":-392,
         "pnl":-441.31
      },
      {
         "__type":"Z.TE",
         "pid":171089,
         "bid":1018316,
         "pn":"YourFxLegend",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/171089\" target=\"_blank\"\u003eYourFxLegend\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e8.8803\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） USD/SEK\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #FF780C;;\"\u003e-391\u003c/span\u003e ピップ。",
         "cc":"LB",
         "cn":"Lebanon",
         "ta":"2 日",
         "tid":397862797,
         "pt":"131.636669981987937088",
         "tc":0,
         "cun":"USD/SEK",
         "pr":8.8803,
         "pi":-391,
         "pnl":-440.18
      },
      {
         "__type":"Z.TE",
         "pid":367542,
         "bid":1804037,
         "pn":"Auto Profit EA",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/367542\" target=\"_blank\"\u003eAuto Profit EA\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e1.1685\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） EUR/USD\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #66D351;\"\u003e15.3\u003c/span\u003e ピップ。",
         "cc":"VN",
         "cn":"Vietnam",
         "ta":"2 日",
         "tid":397862796,
         "pt":"400.1531141235567",
         "tc":0,
         "cun":"EUR/USD",
         "pr":1.1685,
         "pi":15.3,
         "pnl":1.53
      },
      {
         "__type":"Z.TE",
         "pid":364230,
         "bid":1771939,
         "pn":"ZMSWealthgroup",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/364230\" target=\"_blank\"\u003eZMSWealthgroup\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e8.87833\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） USD/SEK\u003c/span\u003e ポジションを閉じた。PnL: \u003cspan class=\"text-highlight\" style=\"color: #FF780C;;\"\u003e-417\u003c/span\u003e ピップ。",
         "cc":"LB",
         "cn":"Lebanon",
         "ta":"2 日",
         "tid":397862795,
         "pt":"131.636669981987936964",
         "tc":0,
         "cun":"USD/SEK",
         "pr":8.87833,
         "pi":-417,
         "pnl":-4.69
      },
      {
         "__type":"Z.TE",
         "pid":352923,
         "bid":1844835,
         "pn":"Knyaz trader",
         "t":"\u003cstrong\u003e\u003ca href=\"/trader/352923\" target=\"_blank\"\u003eKnyaz trader\u003c/a\u003e\u003c/strong\u003eは\u003cspan class=\"text-highlight-plus\"\u003e131.296\u003c/span\u003eで\u003cspan class=\"text-highlight\"\u003e買い（BUY） EUR/JPY\u003c/span\u003e ポジション開いた。",
         "cc":"UA",
         "cn":"Ukraine",
         "ta":"2 日",
         "tid":470608434,
         "pt":"400.1531141271186",
         "tc":0,
         "cun":"EUR/JPY",
         "pr":131.296,
         "pi":0,
         "pnl":0
      }
   ]
}*/
?>
