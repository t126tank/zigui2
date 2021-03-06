#!/bin/bash

folder="stocks/"
item="item.json"
sigma="sigma.json"
csv="sigma.csv"

pre=($(date "+%Y%m%d-%H%M%S-"))
pushd ~/workspace/projects/sigma/
touch $sigma
echo "[]" > $sigma

# elementes=($(/usr/bin/php  select_sym.php))
# elementes=($(/usr/bin/php  select_sym_nikkei225.php))

pushd ${folder}
elementes=($(ls -d *))
popd

nmbr_of_elements=${#elementes[@]}
# echo ${nmbr_of_elements}
# perform every element
for (( i = 0 ; i < nmbr_of_elements ; i++ ))
do
   code=${elementes[$i]}
   sym=${folder}${code}

   # Secure new output folder
   OUT_DIR=$sym/out
   # NEW_DIR=`dirname $OUT_DIR`
   # [ ! -d $NEW_DIR ] && mkdir -p $NEW_DIR
   mkdir -p $OUT_DIR

   touch $sym/out/${item}
   echo "[{" > $sym/out/${item}

   python readCsv.py $sym

   python writeCsv.py $sym > $sym/out/debug.txt

   echo "}]" >> $sym/out/${item}

   python sigma.py $sym

   # update realtime
   # cp $sigma  $pre$sigma
   # sudo cp $sigma  $csv /var/www/html/sigma/
done

# pre=($(date "+%Y%m%d-%H%M%S-"))
cp $sigma  $pre$sigma
sudo cp $sigma  $csv /var/www/html/sigma/

rm  backup.zip
find stocks/ -type d -name "out" -exec rm -rf {} \;

zip backup.zip stocks -r
sudo cp -f backup.zip /var/www/html/sigma/

popd
