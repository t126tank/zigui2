<?php
require ("mysql_pdo/Db.class.php");
require_once ("dbg/dbg.php");

if (!isset($_POST['myusername']) || !isset($_POST['mypassword'])) {
    header("location:login.html");
}
// username and password sent from form
// Never sent unchecked data to mysql server
// Creating md5 hashed to prevent from mysql injections
$myusername=md5(strtolower($_POST['myusername']));
$mypassword=md5($_POST['mypassword']);

// To protect MySQL injection (more detail about MySQL injection)
$myusername = stripslashes($myusername);
$mypassword = stripslashes($mypassword);

$db = new Db();

// $myusername = mysql_real_escape_string($myusername); PDO::quote()
// $mypassword = mysql_real_escape_string($mypassword); PDO::quote()

$db->bindMore(array("email"=>$myusername, "password"=>$mypassword));
$result = $db->single("SELECT * FROM persons WHERE Email = :email AND Password = :password");
// $person_count = array_values($person_count);

// If result matched $myusername and $mypassword, table row must be 1 row
if ($result != null) {
  session_start();
  // Register $myusername, $mypassword and redirect to file "login_success.php"
  $_SESSION['myusername'] = true;
  $_SESSION['mypassword'] = true;
  $_SESSION['is_logged_in'] = true;
  $_SESSION['expires'] = time() + 3600;   // 3600 seconds session lifetime
  header("location:login_success.php");
} else {
  echo "Wrong Username or Password";
  // Redirect to re-login
}
?>
