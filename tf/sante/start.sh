#!/bin/bash

sym="1570"
if [ $1 != "" ] ; then
   sym=$1
fi


pushd ..
python tfCsv2.py $sym

pushd $sym
cp -f iris_test.csv iris_training.csv  ../iris/
popd

popd

python tflearn.py

