<?php

require_once __DIR__ . '/vendor/autoload.php';
use PhpAmqpLib\Connection\AMQPStreamConnection;


$connection = new AMQPStreamConnection('localhost', 5672, 'guest', 'guest');
$channel = $connection->channel();

$channel->queue_declare('hello', false, false, false, false);

// echo ' [*] Waiting for messages. To exit press CTRL+C', "\n";

$callback = function($msg) {
  echo $msg->body; // offer inverted orders to richMT4
};

$channel->basic_consume('hello', '', false, true, false, false, $callback);

echo "9999999999999999999999";
$timeout = 1;
while(count($channel->callbacks)) {
    $channel->wait(null, false, $timeout);
}

$channel->close();
$connection->close();

?>
