<?php 
// Set the JSON header
header("Content-type: text/json");

$jsonStr = '[
   {
      "time":"2016.10.24 08:57",
      "ticket":"638025",
      "op":"sell",
      "price":"1.22077",
      "symbol":"GBPUSD",
      "type":"open",
      "lots":"-0.10000",
      "profits":"-124.00000"
   },
   {
      "time":"2016.10.24 08:58",
      "ticket":"637846",
      "op":"sell",
      "price":"103.882",
      "symbol":"USDJPY",
      "type":"close",
      "lots":"0.100",
      "profits":"-380.000"
   },
   {
      "time":"2016.10.24 08:58",
      "ticket":"638032",
      "op":"sell",
      "price":"103.882",
      "symbol":"USDJPY",
      "type":"open",
      "lots":"-0.100",
      "profits":"-50.000"
   },
   {
      "time":"2016.10.24 09:00",
      "ticket":"637861",
      "op":"buy",
      "price":"103.878",
      "symbol":"USDJPY",
      "type":"close",
      "lots":"-0.100",
      "profits":"290.000"
   },
   {
      "time":"2016.10.24 09:00",
      "ticket":"638043",
      "op":"buy",
      "price":"103.878",
      "symbol":"USDJPY",
      "type":"open",
      "lots":"0.100",
      "profits":"-60.000"
   },
   {
      "time":"2016.10.24 09:01",
      "ticket":"638032",
      "op":"buy",
      "price":"103.865",
      "symbol":"USDJPY",
      "type":"close",
      "lots":"-0.100",
      "profits":"170.000"
   },
   {
      "time":"2016.10.24 09:01",
      "ticket":"638054",
      "op":"buy",
      "price":"103.865",
      "symbol":"USDJPY",
      "type":"open",
      "lots":"0.100",
      "profits":"-60.000"
   }
]';

$arr = json_decode($jsonStr, true);

$close = array();
foreach ($arr as $rkey => $arr){
    if ($arr['type'] == 'close'){
        $close[] = $arr;
    }
}

// The x value is the current JavaScript time, which is the Unix time multiplied by 1000.
$x = time() * 1000;
// The y value is a random number
$y = rand(0, 100);

// Create a PHP array and echo it as JSON
$ret = array($x, $y);
// echo json_encode($ret);
echo json_encode($close);
?>
