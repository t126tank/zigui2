<?php
session_start();

require ("mysql_pdo/Db.class.php");
require_once ("dbg/dbg.php");

if (!$_SESSION['mypassword'] ||
    !$_SESSION['is_logged_in'] || $_SESSION['expires'] < time()) {
    session_unset();
    session_destroy();
    // exit;
    header("location:login.html"); // Redirect to re-login
} else {
    $_SESSION['expires'] = time() + 3600; // refresh the lifetime
    echo "Login Successful ".$_SESSION['myusername']."<br>";
}
?>

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<!-- JS -->
<script type="text/javascript" src="./js/jquery-3.1.1.min.js"></script>
<script type="text/javascript">
<!--

$(document).ready(function() {
    function refresh() {
        var url = "./doRefresh.php";

        $.ajax({
            type: "post",
            url: url,
            // dataType: "json",
            // data: "",
            success: function (msg) {
                var backdata = msg;
                $("#backdata").html(backdata);
                $("#backdata").css({color: "green"});
                // alert('success!');

                // $('.hoge tr').addClass('hv');

	            $('.hoge tr').hover(
		            function() {
			            //hoverクラス「hv」を追加する
			            $(this).addClass('hv');
		            },
		            function() {
		            //マウスアウトしたら
			            //hoverクラス「hv」を削除する
			            $(this).removeClass('hv');
		            }
	            );
	            setTimeout (refresh, 1500);
            },
            error: function(e) {
                console.log(e.message);
            }
        });

        // alert('Hi');
    }
    // setTimeout (refresh, 20);
    refresh();
});

-->
</script>

<!-- CSS -->
<style type="text/css">
    table.hoge tr.hv td {
        background-color: #fff4f8;
    }
</style>


</head>

<body>
echo "hello";

<br>
<a href="logout.php"> Logout </a>
<br>


<span id="backdata"></span>


</body>
</html>
