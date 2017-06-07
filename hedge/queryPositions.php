<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';

ob_start();

$req = array('userId'=>'aaa');

if (!isset($_GET['userId'])) {
    echo "_POST problem";
}
$req['userId'] = $_GET['userId'];

function calPosition($v) {
    return $v['bullVol']*$v['bullPrice'] +
           $v['bearVol']*$v['bearPrice'] +
           $v['cash'];
}

$dao = new RedisDao();

/* Get all visible FIELDs and Values from HashMap startup */
$startupObj = (object) $dao->getTradeStartuphGetAll();  

/* Get userId responding startup trade */
$rtn['result'] = array();

foreach ($startupObj as $key => $value) {
    $v = json_decode($value, true); // $value is encoded in redis
    $lastTradeNode  = $dao->getTradeOne($key, -1);

    if ($v['visible'] &&
        strpos($key, $req['userId']) !== false &&
        strcmp($lastTradeNode['state'], "CLOSE") != 0) { // NOT CLOSE

        $firstTradeNode  = $dao->getTradeOne($key, 0);

        $v['total'] = calPosition($lastTradeNode);
        $v['pl']    = $v['total'] / calPosition($firstTradeNode) - 1;
        $v['first'] = $firstTradeNode['timestamp'];
        $v['last']  = $lastTradeNode['timestamp'];
        $v['times'] = $dao->getTradeTimes($key);
        $rtn['result'][] = array (
            $key => $v
        );
    }
}

echo json_encode($rtn);

$length = ob_get_length();
header("Content-Type: application/json; charset=UTF-8");
header("Content-Length:".$length."\r\n");
header("Accept-Ranges: bytes"."\r\n");

ob_end_flush();

?>

