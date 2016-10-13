<?php
session_start();
if (!session_is_registered(myusername) || !session_is_registered(mypassword) ||
    !$_SESSION['is_logged_in'] || $_SESSION['expires'] < time()) {
  session_unset();
  session_destroy();
  // exit;
  header("location:main_login.php"); // Redirect to re-login
} else {
  $_SESSION['expires'] = time() + 3600; // refresh the lifetime
}
?>

<html>
<body>
Login Successful
</body>
</html>
