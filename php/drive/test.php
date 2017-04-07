<?php
require_once ("../pqs/dbg/dbg.php");
require_once './vendor/autoload.php';
require_once './Client.php';

// require_once './profiler.php';

use Goutte\Client;

$client = new Client();

$crawler = $client->request('GET', 'http://srv/drv/final3NG_files/result.htm');

$crawler->filter('title')->each(function($node)
{
    echo trim($node->text()) . "<br>";
    echo "<hr>";
});

$crawler->filter('span.saitenkekka')->each(function($node)
{
    echo trim($node->text()) . "<br>";
    echo "<hr>";
});
// <td valign="top" width="570">

$cnt = 0;
$crawler->filterXPath('//td[contains(@valign, "top")]')->each(function($node) use(&$cnt)
{
    $ctx  = "";
    $hrkn = "";

    $node->filter('pre.font14pt')->each(function($txt) use (&$ctx)
    {
        // utf8: whitespace from "&nbsp;" to C2A0
        $tmp = str_replace("\xc2\xa0", " ", mb_convert_kana($txt->text(), "s", "UTF-8"));
        $ctx .= trim($tmp);
    });

    $node->filter('pre.font8pt')->each(function($txt) use (&$hrkn)
    {
        $hrkn = trim($txt->text());
    });

    // echo "hirakana" . $hrkn . "<br>";
    if (!empty($ctx)) {
        $cnt++;
        if ($cnt < 180) {
            $type = $cnt % 2? "Answer: ": "Question: ";
            echo $type.$cnt . $ctx . "<br>";
        }
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
