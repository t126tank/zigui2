<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<!-- JS -->
<script type="text/javascript" src="../pqs/js/jquery-3.1.1.min.js"></script>
<script type="text/javascript">
<!--
$(function() {
    $('#send').click(function() {
        var url = "./endpoint.php";
        var type = $('input[name="type"]:checked').val();

        var tbl = "drv_main";
        if (type == 1)
            tbl = "drv_semi";

        var formData = {
            "id"    : $('#id').val(),
            "table" : tbl
        };
        var postData = JSON.stringify(formData);    // Json 2 String

        $.ajax({
            type: "POST",
            url: url,
            // dataType: "html",
            data: postData, // raw json
            success: function (msg) {
               var backdata = msg;
               $("#backdata").html(backdata);
               $("#backdata").css({color: "green"});

               // alert('success!');
               // $('.hoge tr').addClass('hv');

               $('.hoge tr').hover(
                  function() {
                     // hover event cover
                     $(this).addClass('hv');
                  },
                  function() {
                     //hover event leave
                     $(this).removeClass('hv');
                  }
               );
            },
            error: function(e) {
                console.log(e.message);
            }
        });
        // alert('Hi');
    });
});
-->
</script>

<!-- CSS -->
<style type="text/css">
    table.hoge tr.hv-0 td {
        background-color: #ffccff;
    }
    table.hoge tr.hv-1 td {
        background-color: #ffcc99;
    }
    table.hoge tr.hv-2 td {
        background-color: #ccffcc;
    }
    table.hoge tr.hv-3 td {
        background-color: #ccffff;
    }
    table.hoge tr.hv-4 td {
        background-color: #ccccff;
    }
    table.hoge tr.hv-5 td {
        background-color: #ffcccc;
    }
    table.hoge tr.hv td {
        background-color: #ffff33;
    }
</style>


</head>

<body>
<p align="center">
"Have a good test ^_^ ";

<table width="500" border="0" align="center" cellpadding="0" cellspacing="1" bgcolor="#CCCCCC">
<tr>
    <form>
    <td>
    <table width="100%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF">
    <tr>
        <td colspan="3"><strong>Check Form </strong></td>
    </tr>
    <tr>
        <td>Question id</td>
        <td>:</td>
        <td><input type="text" id="id" required /></td>
    </tr>
    <tr>
        <td>Test type</td>
        <td>:</td>
        <td>
            <input id="semi" type="radio" name="type" value="1"><label>仮免許</label>
            <input id="final" type="radio" name="type" value="0" checked><label>本免許</label>
        </td>
    </tr>

    <tr>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
        <td><input type="button" id="send" value="Query"></td>
    </tr>
    </table>
    </td>
    </form>
</tr>
</table>

<span id="backdata"></span>

</body>
</html>

