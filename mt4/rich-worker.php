<?php
include(__DIR__ . '/config.php');

use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Exception\AMQPTimeoutException;

$connection = new AMQPStreamConnection(HOST, PORT, USER, PASS, VHOST);
$channel = $connection->channel();
$channel->queue_declare(TCH, false, false, false, false);

$tradeData = '[';

// echo ' [*] Waiting for messages. To exit press CTRL+C', "\n";
$callback = function($msg) {
   $tradeData = rtrim($tradeData, ']');

   $tradeData .= $msg->body;  // offer inverted orders to richMT4
   $tradeData .= ',';
   $tradeData  = substr($tradeData, 0, -1);
   $tradeData .= ']';
   echo $tradeData;
};

$channel->basic_consume(TCH, '', false, true, false, false, $callback);

$timeout = 1;
while (count($channel->callbacks)) {
    try {
        $channel->wait(null, false, $timeout); // ($allowed_methods=null, $non_blocking = false, $timeout = 0)
    } catch (PhpAmqpLib\Exception\AMQPTimeoutException $e) {
        $channel->close();
        $connection->close();

        exit;
    }
}

$channel->close();
$connection->close();
?>
