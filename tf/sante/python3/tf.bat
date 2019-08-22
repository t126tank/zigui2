
@echo off


if "%1" == "" (
  py -3 mid2Csv3.py  stocks/0000
  py -3 readCsv3.py  stocks/0000
) else (
  py -3 DlN225.py  stocks/0000
  py -3 readCsv3.py  stocks/0000 %1
)

py -3 writeCsv3.py stocks/0000
py -3 tfCsv3.py    stocks/0000

copy /Y  stocks\0000\out\input.csv  iris\.

cd iris/


if "%1" == "" (
  py -3 pqs3_0.py    0000
) else (
  py -3 pqs3_0.py    0000  %1
)

cd ..

REM cls

