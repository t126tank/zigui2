<?php
require ("../pqs/mysql_pdo/Db.class.php"); // setting.ini.php
require_once ("../pqs/dbg/dbg.php");

$jsonObj = file_get_contents('php://input');
$req = json_decode($jsonObj, true);

if (!isset($_POST['myusername']) || !isset($_POST['mypassword'])) {
    // header("location:login.html");
}
// username and password sent from form
// Never sent unchecked data to mysql server
// Creating md5 hashed to prevent from mysql injections
// $myusername=strtolower($_POST['myusername']);
// $mypassword=md5($_POST['mypassword']);

// To protect MySQL injection (more detail about MySQL injection)
// $myusername = stripslashes($myusername);
// $mypassword = stripslashes($mypassword);

$db = new Db();

// $myusername = mysql_real_escape_string($myusername); PDO::quote()
// $mypassword = mysql_real_escape_string($mypassword); PDO::quote()

// $db->bindMore(array("tbl"=>$req['table'], "id"=>intval($req['id'])));
// $result = $db->query("SELECT * FROM :tbl WHERE id = :id");
$result = $db->row("SELECT * FROM ".$req['table']." WHERE id='".$req['id']."'");
// $result = $db->single("SELECT Email FROM ifis_users WHERE Email = :email AND Password = :password");

// $user_count = array_values($user_count);

// If result matched $myusername and $mypassword, table row must be 1 row
if (!empty($result)) {
    session_start();
    // Register $myusername, $mypassword and redirect to file "login_success.php"
    $_SESSION['myusername'] = $result;
    $_SESSION['mypassword'] = true;
    $_SESSION['is_logged_in'] = true;
    $_SESSION['expires'] = time() + 3600;   // 3600 seconds session lifetime
    // header("location:login_success.php");

echo <<<EOF
   <table class="hoge" border=2>
   <tr>
      <th>Question</th>
      <th>Answer</th>
      <th>Explanation</th>
      <th>Image</th>
   </tr>
EOF;
    $img = "-";
    if (!empty($result['image']))
        $img = '<img src="data:image/jpeg;base64,'.base64_encode($result['image']).'"/>';

    // print_r($result);
    // echo json_encode($result);
    $color = rand(1, 60);
    echo '<tr class="hv-'.fmod($color, 6).'">';
    echo '<td>' .$result['question'].'</td>';
    echo '<td>' .$result['answer'].'</td>';
    echo '<td>' .$result['explanation'].'</td>';
    echo '<td>' .$img.'</td>';
    echo '</tr>';

} else {
    echo "Wrong Username or Password !";
    // Redirect to re-login
}
?>
