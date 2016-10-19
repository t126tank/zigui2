
<?php

$t = microtime(true);
$micro = sprintf("%06d", ($t - floor($t)) * 1000000);
$d = new DateTime( date('Y-m-d H:i:s.'.$micro, $t) );
$str = $d->format("Y-m-d H:i:s.u");

echo "Date: $str"."<br>";

echo <<<EOF
<table class="hoge">
<tr>
	<th>見出し</th>
	<th>見出し</th>
	<th>見出し</th>
</tr>
<tr>
	<td>内容</td>
	<td>内容</td>
	<td>内容</td>
</tr>
<tr>
	<td>内容</td>
	<td>内容</td>
	<td>内容</td>
</tr>
</table>
EOF;

?>
