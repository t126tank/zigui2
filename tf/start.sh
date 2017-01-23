#!/bin/bash

sym="stocks/1570"
if [[ ! -z "$1" ]] ; then
   sym=$1
fi

python readCsv2.py $sym


python writeCsv2.py $sym > $sym/out/new.txt
rm -rf /tmp/iris_model/

python tfCsv2.py $sym

pushd iris
cp -f ../$sym/out/iris_test.csv ../$sym/out/iris_training.csv  .
python pqs.py
popd


