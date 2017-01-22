<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

define('ROOTPATH', __DIR__);

define('SYMBOLS',  'data_j.csv');

define('BASEURL',    'http://k-db.com/stocks/');
define('PERIOD',     '-T/1d/');
define('FILETYPE',   '?download=csv');
define('FILETYPE2',  '-T?download=csv');

define('NEW1',  'stocks_');
define('NEW2',  '-T_1d_');
define('NEW3',  '.csv');

$symbols = array();
loadsymbols($symbols);
print_r($symbols);
// $symbols = array(1301); debug

$from = 2007;
$to   = 2017;

foreach ($symbols as $value) {
   for ($year = $from; $year < $to; $year++) {
      $csv = BASEURL . $value . PERIOD . $year . FILETYPE;
      dlcsv($csv, $value, $year);
      sleep(1);
   }
   $csv = BASEURL . $value . FILETYPE2; // Latest 250 items
   dlcsv($csv, $value, $year);
}

echo "done! <br>";

function dlcsv($url, $sym, $year) {
   $opts = array('http' =>
       array(
           'method'  => 'GET',
           //'user_agent '  => "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2) Gecko/20100301 Ubuntu/9.10 (karmic) Firefox/3.6",
           'header' => array(
               'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*\/*;q=0.8',
               'User-Agent:MyAgent/1.0\r\n'
           ),
       )
   );
   $context = stream_context_create($opts);

   $data = file_get_contents($url, false, $context);
   if ($data === false) {
      return;
   }
   $sjis_data = $data;
   // $sjis_data = mb_convert_encoding($data, "UTF-8", "SJIS"); // SJIS -> UTF-8
/*
   $curl_handle = curl_init();
   curl_setopt($curl_handle, CURLOPT_URL, $url);
   curl_setopt($curl_handle, CURLOPT_CONNECTTIMEOUT, 2);
   curl_setopt($curl_handle, CURLOPT_RETURNTRANSFER, 1);
   // curl_setopt($curl_handle, CURLOPT_USERAGENT, 'Your application name');
   $sjis_data = curl_exec($curl_handle);
   curl_close($curl_handle);
*/

   $path = ROOTPATH . "/" . $sym . "/";
   if (!is_dir($path)) {
     // dir doesn't exist, make it
     mkdir($path);
   }

   file_put_contents($path . NEW1 . $sym . NEW2 . $year . NEW3 ,
      $sjis_data, LOCK_EX);
}

function loadsymbols(&$syms) {
   // http://php.net/manual/ja/function.fgetcsv.php remove "25935"
   $row = 1;
   if (($handle = fopen(ROOTPATH . "/" . SYMBOLS, "r")) !== FALSE) {
       while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
           $num = count($data);
           // echo "<p> $num fields in line $row: <br /></p>\n";
           $row++;

           $utf8_type = mb_convert_encoding($data[3], "UTF-8", "SJIS");
           /* Contains in column 市場・商品区分 */
           if (strpos($utf8_type, '市場第一部（内国株）') !== false)
               $syms[] = $data[1]; // コード column

/*
           for ($c=0; $c < $num; $c++) {
               echo $data[$c] . "<br />\n";
           }
*/
       }
       fclose($handle);
   }
}

/*
http://www.jpx.co.jp/markets/statistics-equities/misc/01.html

http://k-db.com/stocks/1301-T/1d/2007?download=csv
http://k-db.com/stocks/1301-T/1d/2008?download=csv
http://k-db.com/stocks/1301-T?download=csv
*/
?>
