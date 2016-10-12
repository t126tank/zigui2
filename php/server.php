<?php

$postJson = json_encode($_POST);
# $postJson = $_POST['myData'];
// echo $postJson;
echo json_encode($_POST);

$jsonObj = array(
	'name' => 'Json',
	'gender' => 'Male',
	'age' => 35,
	'time' => date('Y:m:d g:i:s')
);

$jsonStr = json_encode($jsonObj);

// echo $jsonStr;
?>
