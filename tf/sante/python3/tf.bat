
@echo off

REM cd /d %~dp0

d:
set work="D:\PQS\tf\python3"

cd %work%

if "%1" == "" (
  py -3 mid2Csv3.py  stocks/0000
  py -3 readCsv3.py  stocks/0000
) else (
  py -3 DlN225.py    stocks/0000
  py -3 readCsv3.py  stocks/0000 %1
)

py -3 writeCsv3.py stocks/0000
py -3 tfCsv3.py    stocks/0000

copy /Y  stocks\0000\out\iris_test.csv      iris\.
copy /Y  stocks\0000\out\iris_training.csv  iris\.
copy /Y  stocks\0000\out\input.csv          iris\.

cd iris/


if "%1" == "" (
  py -3 pqs3_0.py    0000
) else (
  py -3 pqs3_0.py    0000  %1

  timeout 1 /nobreak

  set time0=%TIME: =0%
  set fn=item-%DATE:/=%_%time0::=%.json

  for /F "tokens=2 delims==." %%I in ('%SystemRoot%\System32\wbem\wmic.exe OS GET LocalDateTime /VALUE') do set "FileNameDate=%%I"
  set "FileNameDate=%FileNameDate:~0,4%-%FileNameDate:~4,2%-%FileNameDate:~6,2%"

  copy /Y  %work%\stocks\0000\out\item.json   %work%\stocks\0000\out\history\item-%FileNameDate%.json
)


cd ..

REM cls

