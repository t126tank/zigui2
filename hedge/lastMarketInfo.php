<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';

function atm($var) {
    return ($var['atm'] && true);
}

function call($var) {
    return (strcmp("call", $var['type']) == 0);
}

$dao = new RedisDAO();

$timestamp = $dao->getMarketLastTimestamp();
$last = $dao->getMarketHistoryOne($timestamp);

print($last['timestamp'] . " ::: " . $timestamp . "<br>");
$atms = array_filter($last['options'], "atm");
print_r($atms);
print_r($last['hedges']);

echo "<br>---- call filter ----<br>";
$atm = array_filter($atms, "call");
print_r($atm);
?>
