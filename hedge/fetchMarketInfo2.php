<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';

define('HEDGELNK',  'http://stocks.finance.yahoo.co.jp/stocks/detail/?code=');

define('OPTLNK',    'http://svc.qri.jp/jpx/nkopm/');
define('RER',       'Referer');
define('REFV',      'http://www.jpx.co.jp/markets/derivatives/index.html');

use Goutte\Client;

// init
$dao = new RedisDao();
$client = new Client();

//Fetch options
$lnk = 'http://127.0.0.1/hedge/jpx/http_svc.qri.jp_jpx_nkopm_1304.htm'; // OPTLNK
// $client->setHeader(RER, REFV);
$crawlertr = $client->request('GET', $lnk);


$crawlertr->filter('tbody tr')->each(function($crawler) {
    // <td class="a-right" ...
    $crawler->filter('td.a-right')->each(function($node) {
        echo trim($node->text()) . "<br>";
        echo "<hr>";
    });
    // <td valign="top" ...
    $crawler->filterXPath('//td[contains(@valign, "top")]')->each(function($node) {
    });
});


// Fetch hedge pair
$codes = array('1357.t', '1570.t');

foreach ($codes as $value) {
    $lnk = HEDGELNK . $value; // hedge
    // $crawlertr = $client->request('GET', $lnk);
    echo $lnk . '<br>';

} // foreach ($codes as $value) {

// uninit
unset($client);
unset($dao);

?>

