<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
// require_once __DIR__ . '/HistoryTradeUtil.php';

ob_start();

$dao = new RedisDAO();

$req = array();

if (!isset($_GET['startupId'])) {
    echo "_POST problem";
    exit();
}
$req['startupId'] = $_GET['startupId'];

/* Get all trade history from list */
$tradeObj = (object) $dao->getTradeAll($req['startupId']);  

/* Create util */
// $htu = new HistoryTradeUtil($tradeKey, $dao);

/* Iterate each trade record */
$tradeArr = array(); // debug
$init = 0;

foreach ($tradeObj as $key => $value) {
    $v = json_decode($value, true); // $value is encoded in redis
    $timestamp = $v['timestamp'];

    $v['total'] = $v['bullVol']*$v['bullPrice'] +
                  $v['bearVol']*$v['bearPrice'] +
                  $v['cash'];
    if ($init == 0) {
        $init = $v['total'];
    }
    $v['pl'] = $v['total'] / $init - 1;
    $tradeArr[$key] = $v; // debug
}
$rtn['result'] = $tradeArr;
echo json_encode($rtn);

$length = ob_get_length();

header("Content-Type: application/json; charset=UTF-8");
header("Content-Length:".$length."\r\n");
header("Accept-Ranges: bytes"."\r\n");

ob_end_flush();
?>

