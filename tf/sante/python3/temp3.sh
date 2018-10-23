#!/bin/bash

folder="stocks/"
item="item.json"
nn="nn.json"
csv="nn.csv"

pre=($(date "+%Y%m%d-%H%M%S-"))

pushd ~/workspace/bitbucket/nn/workspace/projects/nn

# touch $nn
# echo "[]" > $nn

IFS=$'\n' elementes=($(cat 225-list.txt))
# elementes=($(/usr/bin/php  select_sym_nikkei225.php))
# pushd ${folder}
# elementes=($(ls -d *))
# popd

nmbr_of_elements=${#elementes[@]}
# echo ${nmbr_of_elements}
# perform every element
for (( i = 0 ; i < nmbr_of_elements ; i++ ))
do
   code=${elementes[$i]}
   sym=${folder}${code}

   # Secure new output folder
   OUT_DIR=$sym/out
   NEW_DIR=`dirname $OUT_DIR`
   [ ! -d $NEW_DIR ] && mkdir -p $NEW_DIR
   mkdir -p $OUT_DIR

   touch $sym/out/${item}
#  echo "[{" > $sym/out/${item}

   if [[ $# -gt 0 ]]; then
      python3 readCsv3.py $sym all
   else
      pushd $sym/out/
      zip -r $$.zip iris*.csv data.*
      popd

      python3 readCsv3.py $sym
   fi

   python3 writeCsv3.py $sym > $sym/out/new.txt

   if [[ $# -eq 0 ]]; then
      pushd $sym/out/
      unzip -f $$.zip
      rm -rf *.zip
      popd
   fi

#  rm -rf /tmp/iris_model/

   python3 tfCsv3.py $sym

#  pushd iris
#  cp -f ../$sym/out/iris_test.csv ../$sym/out/iris_training.csv ../$sym/out/input.csv  .
#  env MPLBACKEND=Agg python3 pqs3.py $code

#  echo "}]" >> ../$sym/out/${item}

   # backup model
#   cp model.npz ../$sym/$pre$code.npz

#  popd

#  python3 nn3.py $sym

   # real-time update, for 1st time
   # cp $nn  $pre$nn
   # sudo cp $nn  $csv /var/www/html/nn/
done

# pre=($(date "+%Y%m%d-%H%M%S-"))

# cp $nn  $pre$nn
# cp $nn  $csv  /var/www/html/nn/

# rm  backup.zip
# find stocks/ -type d -name "out" -exec rm -rf {} \;

# zip backup.zip stocks -r
# cp -f backup.zip /var/www/html/nn/

popd
