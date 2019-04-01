* php performs java
  * /var/www/html/example/Service.class
  * /var/www/html/example/service.php （调用 Service.class, 省略后缀.class）
``` 
<?php
exec("java Service", $output);
echo $output[0];
// print_r($output);

// phpinfo();

$to = "to@gls.jp";
$subject = "TEST MAIL";
$message = "Hello!\r\nThis is TEST MAIL.";
$headers = "From: from@gls.jp";

mail($to, $subject, $message, $headers);

?>
```

* crontab
  * 周一至周五，早上8点运行 service.php
```
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed
0  8  *  *  1-5 /bin/php   /var/www/html/example/service.php
```
