<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

$marketStr = file_get_contents("http://localhost/hedge/market.php");
$marketObj = json_decode($marketStr, true); // array

$redis = new Redis();
$redis->connect("127.0.0.1", 6379);
$redis->select(1);

$redis->rpush($marketObj['timestamp'], json_encode($marketObj['options']));
// push when exists
$redis->rpushx($marketObj['timestamp'], json_encode($marketObj['hedges']));

// debug
// print_r($redis->lGet($marketObj['timestamp'], 0));
// print_r($redis->lGet($marketObj['timestamp'], -1));

$redis->close();
// https://redis.io/commands
// https://github.com/phpredis/phpredis
// http://www.runoob.com/redis/redis-tutorial.html
?>
