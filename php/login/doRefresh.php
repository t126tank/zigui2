
<?php

require_once ("dbg/dbg.php");
$newData = 'aaa';

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
    generateTbl(getJsonObj("old.json"), array());

    exit();
}

    // 1) merge buf.json & old.json as old.json
    mergeJson();

    // 2) new data sets as buf.json
    writeJsonObj(getJsonObj("new.json"), "buf.json");

    // 3) set marks to new data for highlights as new.json
    // 4) display old.json & new json
    generateTbl(getJsonObj("old.json"), getJsonObj("new.json"));

function dbgTime() {
    $t = microtime(true);
    $micro = sprintf("%06d", ($t - floor($t)) * 1000000);
    $d = new DateTime( date('Y-m-d H:i:s.'.$micro, $t) );
    $str = $d->format("Y-m-d H:i:s.u");

    // echo "Date: $str"."<br>";
    return $str;
}

function mergeJson() {
    $oldArr = getJsonObj("old.json");
    $bufArr = getJsonObj("buf.json");
    $result = array_merge($bufArr, $oldArr);
    writeJsonObj($result, "old.json");
}

function getJsonObj($jsonfile) {
   $fileLocation = __DIR__ . '/data/'. $jsonfile;

   $file = fopen($fileLocation, "r");
   $jsonObj = trim(fread($file, 8192));
   fclose($file);

   return json_decode($jsonObj, true);
}

function writeJsonObj($arr, $jsonfile) {
   $fileLocation = __DIR__ . '/data/'. $jsonfile;

   $file = fopen($fileLocation, "w");
   fwrite($file, json_encode($arr));
   fclose($file);
}

function generateTbl($arr, $newArr) {
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

    if (sizeof($newArr) != 0) {
        foreach ($newArr as $item) {
            echo '<tr class="hv">';
	        echo '<td>' .dbgTime().' </td>';
	        echo '<td>' .$item['time'].' </td>';
	        echo '<td>' .$item['ticket']. '</td>';
	        echo '<td>' .$item['price'].'</td>';
         	echo '<td>' .$item['type']. '</td>';
            echo '</tr>';
        }
    }

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
