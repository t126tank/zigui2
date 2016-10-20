<?php

$jsonObj = file_get_contents('php://input');

require_once __DIR__ . '/vendor/autoload.php';
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;

$connection = new AMQPStreamConnection('localhost', 5672, 'guest', 'guest');
$channel = $connection->channel();


$channel->queue_declare('hello', false, false, false, false);

$msg = new AMQPMessage(invertJsonObj($jsonObj));
$channel->basic_publish($msg, '', 'hello');

$channel->close();
$connection->close();

function invertJsonObj($obj) {
    $ordArray = json_decode($obj, TRUE);

    array_walk($ordArray, 'cb');

    return json_encode($ordArray);
}

function cb(&$item) {
    if ($item['type'] == 'buy')
        $item['type'] = 'sell';
    else
        $item['type'] = 'buy';
};

?>
