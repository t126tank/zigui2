<?php
// error_reporting(E_ALL);
// ini_set("display_errors", 1);

define('ROOTPATH', __DIR__);
define('SYMBOLS', 'data_j_ori.csv');

$symbols = array();
loadsymbols($symbols);
// print_r($symbols);

foreach ($symbols as $value) {
   echo $value . " ";
}

function loadsymbols(&$syms) {
   // http://php.net/manual/ja/function.fgetcsv.php remove "25935"
   $row = 1;
   if (($handle = fopen(ROOTPATH . "/" . SYMBOLS, "r")) !== FALSE) {
       while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
           $num = count($data);
           // echo "<p> $num fields in line $row: <br /></p>\n";
           $row++;

           $utf8_type = mb_convert_encoding($data[9], "UTF-8", "SJIS");
           /* Contains in column ‹K–Í‹æ•ª */
           if (strpos($utf8_type, 'TOPIX Mid400') !== false)
               $syms[] = $data[1]; // ƒR[ƒh column

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
*/
?>
