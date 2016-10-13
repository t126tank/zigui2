<?php

$host="localhost"; // Host name 
$username=""; // Mysql username 
$password=""; // Mysql password 
$db_name="test"; // Database name 
$tbl_name="members"; // Table name 

// Connect to server and select databse.
mysql_connect("$host", "$username", "$password") or die("cannot connect"); 
mysql_select_db("$db_name") or die("cannot select DB");

// username and password sent from form
// Never sent unchecked data to mysql server
// Creating md5 hashed to prevent from mysql injections
$myusername=md5(strtolower($_POST['username']));
$mypassword=md5($_POST['password']);

// To protect MySQL injection (more detail about MySQL injection)
$myusername = stripslashes($myusername);
$mypassword = stripslashes($mypassword);
$myusername = mysql_real_escape_string($myusername);
$mypassword = mysql_real_escape_string($mypassword);

$sql="SELECT * FROM $tbl_name WHERE username='$myusername' and password='$mypassword'";
$result=mysql_query($sql);

// Mysql_num_row is counting table row
$count=mysql_num_rows($result);

// If result matched $myusername and $mypassword, table row must be 1 row
if ($count==1) {
  // Register $myusername, $mypassword and redirect to file "login_success.php"
  session_register("myusername");
  session_register("mypassword");
  $_SESSION['is_logged_in'] = true;
  $_SESSION['expires'] = time() + 3600;   // 3600 seconds session lifetime
  header("location:login_success.php");
}
else {
  echo "Wrong Username or Password";
  // Redirect to re-login
}
?>
