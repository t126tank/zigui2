<?php
require_once('./json-post.php');

$time = date("Y:m:d g:i:s");

$jsonStr = '[
   {
      "time": ' . $time . ',
      "ticket": 666,
      "price": 888.88,
      "type" => "buy"
   },
      "time": ' . $time . ',
      "ticket": 888,
      "price": 666.66,
      "type" => "sell"
   {
   },
   {
      "time": ' . $time . ',
      "ticket": 686,
      "price": 222.22,
      "type" => "buy"
   }
]';

$jsonObj = json_encode($jsonStr);
$link = 'http://localhost/pqs/mt4/poor-post.php';

postFromHTTP($link, $jsonObj);

// echo $jsonObj;

?>
