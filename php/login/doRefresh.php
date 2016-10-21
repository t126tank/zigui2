
<?php
// require_once ("dbg/dbg.php");
$newData = '';

require_once __DIR__ . '/mt4/vendor/autoload.php';
use PhpAmqpLib\Connection\AMQPStreamConnection;

$connection = new AMQPStreamConnection('localhost', 5672, 'guest', 'guest');
$channel = $connection->channel();

$channel->queue_declare('mmmmm', false, false, false, false);

// echo ' [*] Waiting for messages. To exit press CTRL+C', "\n";


$callback = function($msg) {
  $newData = $msg->body; // offer inverted orders to richMT4
};

$channel->basic_consume('mmmmm', '', false, true, false, false, $callback);


$timeout = 1;
// while(count($channel->callbacks)) {
//     $channel->wait(null, false, $timeout);
// }

$channel->close();
$connection->close();

if (empty($newData)) {
    // return old.json only
    generateTbl(getOld());

    exit();
}

function dbgTime() {
    $t = microtime(true);
    $micro = sprintf("%06d", ($t - floor($t)) * 1000000);
    $d = new DateTime( date('Y-m-d H:i:s.'.$micro, $t) );
    $str = $d->format("Y-m-d H:i:s.u");

    // echo "Date: $str"."<br>";
    return $str;
}


function getOld() {
   $fileLocation = __DIR__ . '/data/old.json';

   $file = fopen($fileLocation, "r");
   $jsonObj = trim(fread($file, 8192));
   fclose($file);

   return json_decode($jsonObj, true);
}

function generateTbl($arr) {
echo <<<EOF
    <table class="hoge">
    <tr>
	    <th>見出し0</th>
	    <th>見出し1</th>
	    <th>見出し2</th>
	    <th>見出し3</th>
	    <th>見出し4</th>
    </tr>
EOF;

    foreach ($arr as $item) {
        echo '<tr>';
	    echo '<td>' .dbgTime().' </td>';
	    echo '<td>' .$item['time'].' </td>';
	    echo '<td>' .$item['ticket']. '</td>';
	    echo '<td>' .$item['price'].'</td>';
     	echo '<td>' .$item['type']. '</td>';
        echo '</tr>';
    }
echo <<<EOF
    </table>
EOF;
}

?>
