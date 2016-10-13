<?php
require ("mysql_pdo/Db.class.php");
require_once ("dbg/dbg.php");

if (!isset($_POST['myData'])) {
    echo 'Failed to register !';
    header("location:register.html"); // return back to register
}

$postJson = json_decode($_POST['myData'], true); // decode to array

// username and password sent from form
// Never sent unchecked data to mysql server
// Creating md5 hashed to prevent from mysql injections
$myusername=md5(strtolower($postJson['myusername']));
$mypassword=md5($postJson['mypassword']);

$firstname=$postJson['firstname'];
$lastname=$postJson['lastname'];
$age=intVal($postJson['age']);
$gender=$postJson['gender'];

$code1=$postJson['code1'];
$keyworld1=$postJson['keyword1'];

$code2=$postJson['code2'];
$keyworld2=$postJson['keyword2'];

// To protect MySQL injection (more detail about MySQL injection)
$myusername = stripslashes($myusername);
$mypassword = stripslashes($mypassword);

$db = new Db();

// $myusername = mysql_real_escape_string($myusername); PDO::quote()
// $mypassword = mysql_real_escape_string($mypassword); PDO::quote()

$db->bindMore(array("email"=>$myusername, "password"=>$mypassword, "firstname"=>$firstname, "lastname"=>$lastname, "sex"=>$gender, "age"=>$age));

// Insert
$insert = $db->query("INSERT INTO persons(Email,Password,Firstname,Lastname,Sex,Age) VALUES(:email,:password,:firstname,:lastname,:sex,:age)");

// Do something with the data 
if ($insert > 0 ) {
  echo 'Succesfully registered your info. !';
} else {
  echo 'Failed to register your info. !';
}

?>
