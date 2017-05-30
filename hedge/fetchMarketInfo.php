<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

$marketStr = file_get_contents("http://localhost/hedge/market.php");
$marketObj = json_decode($marketStr, true); // array

$redis = new Redis();
$redis->connect("127.0.0.1", 6379);
$redis->select(1);

$key = "history";
$redis->rpush($key, $marketStr);

// debug
// print_r($redis->lGet($marketObj['timestamp'], 0));
// print_r($redis->lGet($marketObj['timestamp'], -1));

print_r($redis->lRange($key, 0, -1));
print_r($redis->lGet($key,  0));
print_r($redis->lGet($key, -1));

$redis->close();

?>
