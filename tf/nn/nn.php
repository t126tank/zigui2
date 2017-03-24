<?php
// require_once ("../dbg/dbg.php");
header("Content-type: text/plain; charset=UTF-8");

define("FILELOC",    __DIR__ . '/');
define("TOTAL",      "0");
define("REMOTE",     "http://52.27.86.141/nn/"); // quote.dip.jp
define("TM400",      "http://52.25.39.146/nn/"); // katokunou.dip.jp
define("ALL",        "3");
define("TM400FLG",   "1");

$codeStr    = TOTAL;
$filterStr  = ALL;
$scaleStr   = TM400FLG;

if (isset($_POST['nnData'])) {
    $postJson  = json_decode($_POST['nnData'], true); // decode to array
    $codeStr   = strtolower($postJson['code']);
    $filterStr = strtolower($postJson['filter']);
    $scaleStr  = strtolower($postJson['scale']);

    if (empty(trim($postJson['code'])))
        $codeStr = TOTAL;
}

$code    = intval($codeStr);
$code    = $code < 1? 0: $code;
$codeStr = strval($code);

$scale   = intval($scaleStr);

// Read-in json datasets
$allItems = getJsonObj($scale);

generateTbl($allItems, $codeStr, $filterStr, $scale);

function getJsonObj($scl) {
   $fileLocation = REMOTE;
   if ($scl == 1)
      $fileLocation = TM400;

   $jname = "nn.json";
   $current = file_get_contents($fileLocation . $jname);
   $jsonObj = trim($current);

   // CSV
   $cname = "nn.csv";
   $csv = file_get_contents($fileLocation . $cname);
   file_put_contents(FILELOC . $cname, $csv);

   return json_decode($jsonObj, true);
}

function generateTbl($arr, $cdStr, $ftStr, $scl) {
   $sum = 0.0;
   $total = count($arr);
   $cnt = 0;

   $title = 'TOPIX Core30 + TOPIX Large70 + 1357 + 1570';
   if ($scl == 1)
      $title = 'Nikkei 225';

   foreach ($arr as $item) {
      if (strcmp($item['result'], 1) == 0) {
         $cnt++;
         $sum += $item['possibility'];
      }
   }
   $percent = round($cnt / $total, 4);
   $fMean   = round($sum / $cnt, 4);

   // ref: http://php.net/manual/ja/function.stats-standard-deviation.php#99792
   $bSample = false;
   $fVariance = 0.0;
   foreach ($arr as $i) {
      if (strcmp($i['result'], 1) == 0) {
         $fVariance += pow($i['possibility'] - $fMean, 2);
      }
   }
   $fVariance /= ( $bSample ? $cnt - 1 : $cnt );
   $fStddev = round((float) sqrt($fVariance), 4);
   $fSharpe = round($fMean / $fStddev, 2);

   $nn_idx  = round(1000 * $percent * $fSharpe);

echo <<<EOF
   <br>
   <section>
   <h1>Summary of UP %2.2 Trend:</h1>
   <details>
EOF;

echo '<summary><font color="red"><b>' . $title . ' (NN Index:' . $nn_idx . ')</b></font></summary>';
echo '<dl>';

echo '<dt>UP 2.2% QTY </dt><dd>' . $cnt . ' (In ' . $total . ')</dd>';
echo '<dt>UP 2.2% PERCENT </dt><dd>' . 100*$percent . '%</dd>';
echo '<dt>Average Possibility </dt><dd>' . 100*$fMean . '% (STDEV: ' . $fStddev . ', Sharpe Ratio: ' . $fSharpe . ')</dd>';

echo <<<EOF
   </dl>
   </details>
   </section>

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

    $color = rand(1, 60);
    foreach ($arr as $item) {
        if ((strcmp($cdStr, TOTAL) == 0 ||
             strcmp($item['code'], $cdStr) == 0) &&
            (strcmp($item['result'], $ftStr) == 0 ||
             strcmp($ftStr, ALL) == 0)) {
            echo '<tr class="hv-'.fmod($color, 6).'">';
            output($item);
            echo '</tr>';
         }
    }

echo <<<EOF
    </table>
EOF;
}

function output($item) {
   // http://stocks.finance.yahoo.co.jp/stocks/detail/?code=1570.t
   echo '<td><a href="http://stocks.finance.yahoo.co.jp/stocks/detail/?code=' .$item['code']. '.T&d=1w" target="_blank">' .$item['code']. '</a></td>';
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

