<?php
ob_start();

require ("../pqs/mysql_pdo/Db.class.php"); // setting.ini.php
require_once ("../pqs/dbg/dbg.php");

// $jsonObj = file_get_contents('php://input');
// $req = json_decode($jsonObj, true);

$req = array('table'=>'drv_main', 'id'=>1);

if (!isset($_GET['table']) || !isset($_GET['id'])) {
    echo "_POST problem";
}
$req['table'] = $_GET['table'];
$req['id']    = intval($_GET['id']);

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
    $rnt = array(
        'kind'=>'Listing',
        'data'=>array(
            'modhash'=>'',
            'children'=>array(),
            'after'=>'t3_660ns7',
            'before'=>null
        )
    );
    $result['image'] = base64_encode($result['image']);
    $rnt['data']['children'][] = $result;
    echo json_encode($rnt);

    $length = ob_get_length();
    header("Content-Type: application/json; charset=UTF-8");
    header("Content-Length:".$length."\r\n");
    header("Accept-Ranges: bytes"."\r\n");

    ob_end_flush();

} else {
    echo "Wrong Username or Password !";
    // Redirect to re-login
}
?>
