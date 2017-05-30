<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

function atm($var) {
    return ($var['atm'] && true);
}

$key = "last";

$redis = new Redis();
$redis->connect("127.0.0.1", 6379);
$redis->select(1);

$timestamp = $redis->hGet($key, $key);

$key = "history";

$last = json_decode($redis->hGet($key, $timestamp), true);
$redis->close();

print($last['timestamp'] . "<br>");
$atms = array_filter($last['options'], "atm");
print_r($atms);

?>
