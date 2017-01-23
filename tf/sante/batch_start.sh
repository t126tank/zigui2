#!/bin/bash

folder="stocks/"
item="item.json"

pushd ${folder}
elementes=($(ls -d *))
nmbr_of_elements=${#elementes[@]}
popd

# echo ${nmbr_of_elements}
# perform every element
for (( i = 0 ; i < nmbr_of_elements ; i++ ))
do
   code=${elementes[$i]}
   sym=${folder}${code}

   touch $sym/out/${item}
   echo "{" > $sym/out/${item}

   python readCsv2.py $sym

   python writeCsv2.py $sym > $sym/out/new.txt
   rm -rf /tmp/iris_model/

   python tfCsv2.py $sym

   pushd iris
   cp -f ../$sym/out/iris_test.csv ../$sym/out/iris_training.csv ../$sym/out/input.csv  .
   python pqs.py $code

   echo "}" >> ../$sym/out/${item}
   popd

   touch "nn.json"
   echo "[]" > "nn.json"
   python nn.py $sym

done











