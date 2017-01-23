<?php
// require_once ("../dbg/dbg.php");
header("Content-type: text/plain; charset=UTF-8");

define("FILELOC", __DIR__ . '/');
define("TOTAL", "0");

$codeStr = TOTAL;
if (isset($_POST['nnData'])) {
    $postJson = json_decode($_POST['nnData'], true); // decode to array
    $codeStr  = strtolower($postJson['code']);

    if (empty(trim($postJson['code'])))
        $codeStr = TOTAL;
}

$code    = intval($codeStr);
$code    = $code < 1? 0: $code;
$codeStr = strval($code);

// Read-in json datasets
$allItems = getJsonObj("nn.json");

generateTbl($allItems, $codeStr);

function getJsonObj($jsonfile) {
   $fileLocation = FILELOC . $jsonfile;

   $current = file_get_contents($fileLocation);
   $jsonObj = trim($current);

   return json_decode($jsonObj, true);
}

function generateTbl($arr, $cdStr) {
echo <<<EOF
   <table class="hoge">
   <tr>
      <th>Code</th>
      <th>Training items</th>
      <th>Tested items</th>
      <th>Possibility</th>
      <th>Reference price</th>
      <th>From Date</th>
      <th>Result</th>
      <th>Price 0</th>
      <th>Price 1</th>
      <th>Price 2</th>
   </tr>
EOF;

    $color = rand(1, 30);
    foreach ($arr as $item) {
        if (strcmp($cdStr, TOTAL) == 0 ||
            strcmp($item['code'], $cdStr) == 0) {
            echo '<tr class="hv-'.fmod($color, 3).'">';
            output($item);
            echo '</tr>';
         }
    }

echo <<<EOF
    </table>
EOF;
}

function output($item) {
   echo '<td>' .$item['code'].'</td>';
   echo '<td>' .$item['training'].'</td>';
   echo '<td>' .$item['test'].'</td>';
   echo '<td>' .$item['possibility'].'</td>';
   echo '<td>' .$item['refPrice'].'</td>';
   echo '<td>' .$item['fromDate'].'</td>';
   echo '<td>' .$item['result'].'</td>';
   echo '<td>' .$item['price0'].'</td>';
   echo '<td>' .$item['price1'].'</td>';
   echo '<td>' .$item['price2'].'</td>';
}

?>

