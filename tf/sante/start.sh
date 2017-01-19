#!/bin/bash

sym="1570"
if [[ ! -z "$1" ]] ; then
   sym=$1
fi


pushd ..

python writeCsv2.py $sym > $sym/out/new.txt
rm -rf /tmp/iris_model/

python tfCsv2.py $sym

pushd $sym/out
cp -f iris_test.csv iris_training.csv  ../../iris/
popd

popd

python tflearn.py

