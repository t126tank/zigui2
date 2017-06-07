<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';

$marketStr = file_get_contents("http://localhost/hedge/market.php");
$marketObj = json_decode($marketStr, true); // array

$dao = new RedisDAO();

$timestamp = strtotime($marketObj['timestamp']);
$dao->setMarketHistoryOne($timestamp, $marketObj);
print_r($dao->getMarketHistoryOne($timestamp));

/*
$redis->rpush($key, $marketStr);

// debug
// print_r($redis->lGet($marketObj['timestamp'], 0));
// print_r($redis->lGet($marketObj['timestamp'], -1));

print_r($redis->lRange($key, 0, -1));
print_r($redis->lGet($key,  0));
print_r($redis->lGet($key, -1));
*/

$dao->setMarketLastTimestamp($timestamp);
print("<br> Last timestamp: " . $dao->getMarketLastTimestamp());

unset($dao);
// https://redis.io/commands
// https://github.com/phpredis/phpredis
// http://www.runoob.com/redis/redis-tutorial.html

?>
