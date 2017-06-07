<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);

require_once __DIR__ . '/RedisDao.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/Client.php';

define('ROOTPATH', __DIR__);
define('HEDGELNK', 'http://stocks.finance.yahoo.co.jp/stocks/detail/?code=');

define('OPTLNK', 'http://svc.qri.jp/jpx/nkopm/');
define('RER', 'Referer');
define('REFV', 'http://www.jpx.co.jp/markets/derivatives/index.html');


use Goutte\Client;

$client = new Client();

//Fetch
$lnk = 'http://127.0.0.1/hedge/jpx/http_svc.qri.jp_jpx_nkopm_1304.htm';// OPTLNK
// $client->setHeader(RER, REFV);
$crawlertr = $client->request('GET', $lnk);


// Fetch hedge pair
$codes = array("1357.t", "1570.t");


foreach ($codes as $value) {

$lnk = HEDGELNK . $value; // hedge
$crawlertr = $client->request('GET', $lnk);


$cnt = 0;
$subcnt = 0;
$illus = false;
$id = 0;
$pid = 0;

$crawlertr->filter('tbody tr')->each(function($crawler) use(&$cnt, &$illus, &$subcnt, $lnk, &$id, &$pid) {
    $crawler->filter('title')->each(function($node) {
        echo trim($node->text()) . "<br>";
        echo "<hr>";
    });

    $crawler->filter('span.saitenkekka')->each(function($node)
    {
        echo trim($node->text()) . "<br>";
        echo "<hr>";
    });
    // <td valign="top" width="570">


// tr start
$crawler->filterXPath('//td[contains(@valign, "top")]')->each(function($node) use(&$cnt, &$illus, &$subcnt, $lnk, &$id, &$pid) {
    $ctx  = "";
    $hrkn = "";
    $type = "";

    $node->filter('pre.font14pt')->each(function($txt) use (&$ctx)
    {
        // utf8: ？ (EFBC9F) to ?
        // $tmp = str_replace("\xef\xbc\x9f", "?", mb_convert_kana($txt->text(), "s", "UTF-8"));
        // utf8: whitespace from "&nbsp;" to C2A0
        $tmp = str_replace("\xc2\xa0", " ", mb_convert_kana($txt->text(), "s", "UTF-8"));
        $ctx .= trim($tmp);
    });

    $node->filter('pre.font8pt')->each(function($txt) use (&$hrkn)
    {
        $hrkn = trim($txt->text());
    });

    $node->filter('pre.font8pt')->each(function($txt) use (&$hrkn)
    {
        $hrkn = trim($txt->text());
    });

    // echo "hirakana" . $hrkn . "<br>";
    if (!empty($ctx)) {
        if (strpos($ctx, "\xef\xbc\x9f") !== false) {
            $illus = true;
            $subcnt = 0;
        } else {
            $type = $cnt % 2? "explanation": "question";
            if (!$illus)
                update_common($id, $type, $ctx);
        }

        // illustration
        if ($illus) {
            if ($subcnt == 0) {
                $type = "question";
                $id = insert_common($type, $ctx);
                $pid = $id;
            } else if ($subcnt % 2 == 0) {
                $type = "question";
                update_common($id, $type, $ctx);
                update_common($id, "parent", $pid);
            } else if ($subcnt == 7) {
                $type = "explanation";
                $illus = false;
                update_common($pid, $type, $ctx);
            }
            $subcnt++; // +1
        }
        $cnt++;

        // Not illustration
        if ($subcnt % 2 || $subcnt == 0 || $subcnt == 8)
            echo $type. $ctx . "<br>";
    }

    if (count($node->filter('img'))) {
        $node->filter('img')->each(function($pic) use(&$id) {
            $img = $pic->attr('src');

            if (strpos($img, "false_on.gif") !== false) {
                $id = insert_common("answer", 0);
                echo "正解は batsu ".$id."<br>";
            }
            if (strpos($img, "true_on.gif") !== false) {
                $id = insert_common("answer", 1);
                echo "正解は maru ".$id."<br>";
            }
        });
    }
  
    /*
    static $cnt = 0;
    $ctx =trim($node->text());

    if ($cnt == 0)
        echo "Question: <br>";
    else if ($cnt == 1)
        echo "Answer: <br>";

    if (strpos($ctx, '。') !== false) {
        $cnt++;
    }
    echo $ctx . "<br>";
    if ($cnt == 2) {
        echo "<hr>";
        $cnt = 0;
    }
    */
});

// Create Dao
$dao = new RedisDAO();

// Save history node into Redis
$timestamp = strtotime($marketObj['timestamp']);
$dao->setMarketHistoryOne($timestamp, $marketObj);
print_r($dao->getMarketHistoryOne($timestamp));

// Save last timestamp into Redis
$dao->setMarketLastTimestamp($timestamp);
print("<br> Last timestamp: " . $dao->getMarketLastTimestamp());

// Free Dao
unset($dao);


if (count($crawler->filter('td img'))) {
    $crawler->filter('img')->each(function($pic) use($lnk, $id) {
        $img = $pic->attr('src');

        if (strpos($img, "jpg") !== false) {
            $loc = ROOTPATH . $lnk . $img;
            echo "Picture is: " . $loc . "<br>";
            $img_file = access_image($loc);
            update_common($id, "image", $img_file);
        }
    });
}
// tr end

});

} // foreach ($codes as $value) {


function update_common($id, $col, $val) {
    include 'lib/config.php';
    include 'lib/opendb.php';

    $query = "UPDATE drv_semi ".
             "SET " . $col ." = '$val' ".
             "WHERE id='$id'";

    mysql_query("SET NAMES UTF8");
    mysql_query($query) or die('Error, query failed');

    include 'lib/closedb.php';
}

function insert_common($col, $val) {
    include 'lib/config.php';
    include 'lib/opendb.php';

    $rtn = 0;
    /*
    $fp      = fopen($tmpName, 'r');
    $content = fread($fp, filesize($tmpName));
    $content = addslashes($content);
    fclose($fp);

    date_default_timezone_set('Asia/Tokyo');
    $date = date('Y-m-d H:i:s', time());
    echo $date."<br>";
    */
    $query = "INSERT INTO drv_semi (".$col.") ".
             "VALUES ('$val');";
echo $query . "<br>";
    mysql_query("SET NAMES UTF8");
    mysql_query($query) or die('Error, query failed');

    $rtn = mysql_insert_id();

    include 'lib/closedb.php';
    return $rtn;
}

function access_image($img_loc) {
    // Read image content
    $fp = fopen($img_loc, 'r');
    $stream = fread($fp, filesize($img_loc));
    $stream = addslashes($stream);
    fclose($fp);

    // Delete image file
    // unlink($img_loc);

    return $stream;
}



