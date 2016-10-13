<?php
session_start();

require_once ("dbg/dbg.php");

if (!$_SESSION['myusername'] || !$_SESSION['myusername'] ||
    !$_SESSION['is_logged_in'] || $_SESSION['expires'] < time()) {
  session_unset();
  session_destroy();
  // exit;
  header("location:login.html"); // Redirect to re-login
} else {
  $_SESSION['expires'] = time() + 3600; // refresh the lifetime
}
?>

<html>
<body>
Login Successful
</body>
</html>
