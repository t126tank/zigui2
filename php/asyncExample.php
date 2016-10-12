<?php
require_once('pqs/dbg/dbg.php');

echo '<a href=./pqs/testredis.php>Test Redis</a><br>';

$output = file_get_contents('http://some-server/service/doReq.php');
echo $output;

$args = array(
	'1st' => 'para1',
	'2nd' => 'para2',
	'3rd' => 'para3333333333333333333333333'
);

$i = 10;
while ($i-- > 0) {
	post_without_wait('http://some-server/service/doReq.php', $args);
	sleep(2); // 20 sec stop
}

function post_without_wait($url, $params)
{
    $post_params = array();
    foreach ($params as $key => &$val) {
      if (is_array($val))
        $val = implode(',', $val);

      $post_params[] = $key.'='.urlencode($val);
    }
    $post_string = implode('&', $post_params);

    echo $post_string;

    $parts=parse_url($url);

    $fp = fsockopen($parts['host'],
        isset($parts['port'])?$parts['port']:80,
        $errno, $errstr, 30);

    $out = "POST ".$parts['path']." HTTP/1.1\r\n";
    $out.= "Host: ".$parts['host']."\r\n";
    $out.= "Content-Type: application/x-www-form-urlencoded\r\n";
    $out.= "Content-Length: ".strlen($post_string)."\r\n";
    $out.= "Connection: Close\r\n\r\n";
    if (isset($post_string)) $out.= $post_string;

    fwrite($fp, $out);
    fclose($fp);
}

echo '<br>';
echo date("Y:m:d g:i:s");

############################
require_once("dbg/dbg.php");
// error_reporting(E_ALL);
// ini_set("display_errors", 1);

$.get("doReq.php", { name: "fdipzone"} );
<img src="doRequest.php?name=fdipzone">
############################

############################
$ch = curl_init(); 
$curl_opt = array( 
	CURLOPT_URL, 'http://some-server/service/doReq.php',
	CURLOPT_RETURNTRANSFER, 1,
	CURLOPT_TIMEOUT, 1
); 

curl_setopt_array($ch, $curl_opt);
curl_exec($ch);
curl_close($ch);
############################

############################
define('CPATH', '__DIR__');

// popen — open process file handler  
resource popen ( string $command , string $mode )
pclose(popen('php '.CPATH.'/doReq.php &', 'r'));
############################

?>

