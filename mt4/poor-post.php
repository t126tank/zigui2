<?php
// require_once ("../dbg/dbg.php");

$jsonObj = file_get_contents('php://input');
/*
$time = date("Y:m:d g:i:s");
$data = array(
         array(
            "time" => $time,
            "ticket" => 666,
            "price" => 888.88,
            "type" => "open",
            "op" => "buy"
          ),
         array(
            "time" => $time,
            "ticket" => 888,
            "price" => 666.66,
            "type" => "open",
            "op" => "sell"
         ),
         array(
            "time" => $time,
            "ticket" => 686,
            "price" => 222.22,
            "type" => "close",
            "op" => "buy")
);
$jsonObj = json_encode($data);
*/
if (empty($jsonObj)) exit();
include(__DIR__ . '/config.php');

use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;

$connection = new AMQPStreamConnection(HOST, PORT, USER, PASS, VHOST);
$channel = $connection->channel();
$channel->queue_declare(TCH, false, false, false, false);


// $channel->exchange_declare(TCH, 'fanout', false, false, false);
// echo $jsonObj;
// echo invertJsonObj($jsonObj);
// dbgWrite(invertJsonObj($jsonObj));

$msg = new AMQPMessage(invertJsonObj($jsonObj));

$channel->basic_publish($msg, '', TCH);

$channel->close();
$connection->close();

function invertJsonObj($obj) {
    $ordArray = json_decode($obj, TRUE);
    foreach ($ordArray as &$item) {
        array_walk($item, 'cb');
    }

    return json_encode($ordArray);
}

function cb(&$val, $key) {
    if ($key == 'op' && $val == 'buy')
        $val = 'sell';
    else if ($key == 'op' && $val == 'sell')
        $val = 'buy';
};

function dbgWrite($str) {

   $fileLocation = __DIR__ . '/ttmmpp.txt';

   $file = fopen($fileLocation, "w");
   fwrite($file, $str);
   fclose($file);
}
?>

