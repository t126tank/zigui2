<?php

require_once(__DIR__ .'/json-post.php');

// $postJson = json_encode($_POST);
// $json_input_data=json_decode(file_get_contents('php://input'), TRUE);

$link = 'http://localhost/pqs/mt4/rich-worker.php';

$options = array(
    'http' => array(
        'header' => 'Connection: close'
        // 'ignore_errors' => true
    )
);


$ctx = stream_context_create($options);
$jsonObj = file_get_contents($link, false, $ctx);

preg_match('/HTTP\/1\.[0|1|x] ([0-9]{3})/', $http_response_header[0], $matches);
$status_code = $matches[1];

switch ($status_code) {
    case '200':
        // 200の場合
        break;
    case '404':
        // 404の場合
        exit();
        break;
    default:
        break;
}

// trading
sleep(1);

$link = 'http://localhost/pqs/mt4/rich-post.php';
postFromHTTP($link, $jsonObj);


?>
