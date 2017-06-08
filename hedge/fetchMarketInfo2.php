<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';

define('HEDGELNK',  'http://stocks.finance.yahoo.co.jp/stocks/detail/?code=');

define('OPTLNK',    'http://svc.qri.jp/jpx/nkopm/');
define('RER',       'Referer');
define('REFV',      'http://www.jpx.co.jp/markets/derivatives/index.html');

define('ATM',       'ATM');

use Goutte\Client;

function getTimeStr($str) {
   $rtn = "0:0";
   if (!(strpos($str, '-') !== false)) {
      $parts = explode('(', $str);
      $rtn = str_replace(')', '', $parts[1]);
   }
   return " " . $rtn . ":0";  // H:i:s
}

function getPriceStr($str) {
   $rtn = 0;
   if (!(strpos($str, '-') !== false)) {
      $parts = explode('(', $str);
      $rtn = $parts[0];
   }
   return $rtn;
}
function getKStr($str) {
   // preg_match_all('!\d!', $str, $matches);
   // (int)implode('', $matches[0]);
   return preg_replace('/[^0-9]+/', '', $str);
}
function isAtm($str) {
   // utf8: ？ (EFBC9F) to ?
   // $tmp = str_replace("\xef\xbc\x9f", "?", mb_convert_kana($txt->text(), "s", "UTF-8"));
   // utf8: whitespace from "&nbsp;" to C2A0
   return (strpos(
               str_replace("\xc2\xa0", "", mb_convert_kana($str, "s", "UTF-8")),
               ATM) !== false)?
         true:
         false;
}
function converPara($str) {
   $rtn = 0.0;
   if (is_numeric($str)) {
      $rtn = doubleval($str);
   }
   return $rtn;
}

// init
$dao = new RedisDao();
$client = new Client();
// Init market info object to be set in Redis finally
$marketObj = array();

// Fetch options
$lnk = OPTLNK;
$lnk = 'http://127.0.0.1/hedge/jpx/http_svc.qri.jp_jpx_nkopm_1304.htm';
$client->setHeader(RER, REFV);
$crawlerAll = $client->request('GET', $lnk);

// last updated time: <dl><dd> ...
$historyDatetime = date('Y/m/d H:i:s');
$marketObj['timestamp'] = $historyDatetime;
// echo $marketObj['timestamp'] . "<br>";

$marketTime = array();
$idx = 0;
$crawlerAll->filter('dl dd')->each(function($node) use (&$marketTime, &$idx) {
   // [0] - last update time     yyyy/MM/dd hh:mm
   // [1] - on trading date      yyyy/MM/dd
   // [2] - expire date          yyyy/MM/dd
   $marketTime[$idx++] = trim($node->text());
});
$onTradeDate = $marketTime[1];
$expireDate = str_replace('/', '', $marketTime[2]);
// echo $expireDate . "<br>";

// Options info
$options = array();
$idx = 0;

// <table class="price-table" ...><tbody class="price-info-scroll" ...
$crawlerAll->filter('table.price-table tbody.price-info-scroll')->each(function($crawler) use (&$options, &$idx, $expireDate, $onTradeDate) {

    // <tr class="row-num" ... <tr class="row-num.atm-pos" ... <td ...
    $crawler->filter('tr.row-num td')->each(function($node) use (&$options, &$idx, $expireDate, $onTradeDate) {
         $item_cnt = 17;
         $itemidx = 2 * (int)floor($idx / $item_cnt); // pair
         $txt = trim($node->text());

         if ($idx % $item_cnt == 7) {        // call
            $options[$itemidx]['update'] = $onTradeDate . getTimeStr($txt);
            $options[$itemidx]['price']  = intval(getPriceStr($txt));
         } else if ($idx % $item_cnt == 9) { // put
            $options[$itemidx+1]['update'] = $onTradeDate . getTimeStr($txt);
            $options[$itemidx+1]['price']  = intval(getPriceStr($txt));
         } else if ($idx % $item_cnt == 8) { // k
            // call
            $atm = isAtm($txt);
            $options[$itemidx]['k']   = intval(getKStr($txt));
            $options[$itemidx]['type']   = "call";
            $options[$itemidx]['expire'] = $expireDate;
            $options[$itemidx]['atm']    = $atm;
            // put
            $options[$itemidx+1]['k'] = $options[$itemidx]['k'] ;
            $options[$itemidx+1]['type']   = "put";
            $options[$itemidx+1]['expire'] = $expireDate;
            $options[$itemidx+1]['atm']    = $atm;
         }
         $idx++;
         // print_r($options[$itemidx]);
         // echo "<br>!!!!!!!!!!!" . $itemidx . "<br>";
    });

    // Delta, Gamma, Theta, Vega
    // <table class="greek-value-table"><tbody><tr><td class="a-right" ...
    $idx = 0;
    $crawler->filter('table.greek-value-table tbody tr td.a-right')->each(function($node) use (&$options, &$idx) {
         $para_cnt = 4;
         $optidx = (int)floor($idx / $para_cnt);
         $txt = trim($node->text());

         if ($idx % $para_cnt == 0) {
            $options[$optidx]['delta'] = $txt;
         } else if ($idx % $para_cnt == 1) {
            $options[$optidx]['gama'] = $txt;
         } else if ($idx % $para_cnt == 2) {
            $options[$optidx]['theta'] = $txt;
         } else { // if ($idx % $para_cnt == 3)
            $options[$optidx]['vega'] = $txt;  // !!! Last
         }
         $idx++;
         // echo "<br>!!!!!!!!!!!" . $optidx . "<br>";
    });

    // <td valign="top" ...
    $crawler->filterXPath('//td[contains(@valign, "top")]')->each(function($node) {
    });
});

// print_r($options);
$realOptions = array();

foreach ($options as $opt) {
   if (is_numeric($opt['delta'])) {
      $value = array (
         'update' => '',
         'k' => 0,
         'expire' => '',
         'type' => '',
         'price' => 0,
         'atm' => false,
         'delta' => 0.0
      );
      $value['update'] = $opt['update'];
      $value['k']      = $opt['k'];
      $value['expire'] = $opt['expire'];
      $value['type']   = $opt['type'];
      $value['price']  = $opt['price'];
      $value['atm']    = $opt['atm'];
      $value['delta']  = doubleval($opt['delta']);
      // insert
      $realOptions[]   = $value;
   }
}
$marketObj['options'] = $realOptions;

// Fetch hedge pair
$codes = array('1357.t', '1570.t');

$hedges = array();
$bull = true;
foreach ($codes as $value) {
    $lnk = HEDGELNK . $value; // hedge
    // $lnk = 'http://127.0.0.1/hedge/jpx/yahoo.html'; // OPTLNK
    $crawler = $client->request('GET', $lnk);

    // echo $lnk . '<br>';
    $update = '';
    $price  = 0;

    // <div class="forAddPortfolio"><dl class="stocksInfo clearFix"><dd class="yjSb real"><span>...
    $crawler->filter('div.forAddPortfolio dl.stocksInfo.clearFix dd.yjSb.real span')->each(function($node) use (&$update, $onTradeDate) {
         $update = $onTradeDate . ' ' .trim($node->text()) . ':0';
    });
    // <table class="stocksTable" <tbody><tr><td class="stoksPrice">
    $crawler->filter('table.stocksTable tbody tr td.stoksPrice')->each(function($node) use (&$price) {
         $price = doubleval(getKStr(trim($node->text())));
    });

   if ($bull) {
      $hedges['bull']['code'] = "1357";
      $hedges['bull']['price'] = $price;
      $hedges['bull']['update'] = $update;
      $bull = false;
   } else {
      $hedges['bear']['code'] = "1570";
      $hedges['bear']['price'] = $price;
      $hedges['bear']['update'] = $update;
   }
} // foreach ($codes as $value) {
$marketObj['hedges'] = $hedges;

// 1.1
$timestamp = strtotime($marketObj['timestamp']);
$dao->setMarketHistoryOne($timestamp, $marketObj);
print_r($dao->getMarketHistoryOne($timestamp));

// 1.2
$dao->setMarketLastTimestamp($timestamp);
print("<br> Last timestamp: " . $dao->getMarketLastTimestamp());


// uninit
unset($client);
unset($dao);

?>

