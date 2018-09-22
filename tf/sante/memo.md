|  Header-Key  |  Header-Val  |
| ---- | ---- |
|  Accept  |  text/html,application/xhtml+xm…plication/xml;q=0.9,*/*;q=0.8  |
|  Accept-Encoding  |  gzip, deflate, br  |
|  Accept-Language  |  ja,en-US;q=0.7,en;q=0.3  |
|  Connection	  |  keep-alive  |
|  Content-Length  |  24  |
|  Content-Type  |  application/x-www-form-urlencoded  |
|  Cookie  |  _ga=GA1.2.1716909546.153757503…1052914183.1537575036; _gat=1  |
|  Host  |  kabuoji3.com  |
|  Referer  |  https://kabuoji3.com/stock/download.php  |
|  Upgrade-Insecure-Requests  |  1  |
|  User-Agent  |  Mozilla/5.0 (Windows NT 6.1; W…) Gecko/20100101 Firefox/62.0  |


|  Form Para-Key  |  Form Para-Val  |
| ---- | ---- |
|  code  |  1301  |
|  csv  |  ??  |
|  year  |  2017  |


```
$ curl -X POST -H 'Content-Type:application/x-www-form-urlencoded' -H 'User-Agent:Mozilla/5.0 (Windows NT 6.1; W…) ecko/20100101 Firefox/62.0' -d 'code=1301' -d 'csv=1' -d 'year=2017' https://kabuoji3.com/stock/file.php --insecure
$ curl -X POST -H 'Content-Type:application/x-www-form-urlencoded' -H 'User-Agent:Mozilla/5.0 (Windows NT 6.1; W…) ecko/20100101 Firefox/62.0' -d 'code=1301' -d 'year=2017' -d 'csv=' -o stocks_1301-T_1d_2017.csv -L https://kabuoji3.com/stock/file.php --insecure
```
> LANG=ja_jp.sjis/utf-8  
> teraterm = sjis
