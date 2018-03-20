# TensorFlow Classifier of Iris for predicting stock price trend(分类器预测股票价格)

## Summary(说明)
◎ Dataset(原始数据)

■ Intermediate Data(加工数据)
- Ⅰ JSON (step 1)
- Ⅱ CSV  (step 2)

★ Target Data(目标数据)
- ❶ For Validation(检证用)
- ❷ For Training(训练用)

◆ Performing scripts(执行脚本)
- ① Python
- ② Bash Script

### CLICK ☞ [Dir structure - 目录结构](https://raw.githubusercontent.com/t126tank/zigui2/master/tf/sante/readme.md)

```
.
├── readCsv2.py                           ◆①
├── writeCsv2.py                          ◆①
├── tfCsv2.py                             ◆①
├── start.sh                              ◆②
├── stocks
│   ├── 1570
│   │   ├── out
│   │   │   ├── data.json              ■Ⅰ
│   │   │   ├── data.csv               ■Ⅱ
│   │   │   ├── iris_test.csv          ★❶  ─┐
│   │   │   └── iris_training.csv      ★❷  ─┼┐
│   │   ├── stocks_1570-T_1d_2013.csv   ◎      ││
│   │   ├── stocks_1570-T_1d_2014.csv   ◎      ││
│   │   ├── stocks_1570-T_1d_2015.csv   ◎      ││
│   │   ├── stocks_1570-T_1d_2016.csv   ◎      ││
│   │   ├── stocks_1570-T_1d_2017.csv   ◎      ││
│   │   └── stocks_1570-T.csv           ◎      ││
│   └── 4536                                     ││
│        ├── out                                 ││
│        │   ├── data.json              ■Ⅰ    ││
│        │   ├── data.csv               ■Ⅱ    ││
│        │   ├── iris_test.csv          ★❶  ─┤│
│        │   └── iris_training.csv      ★❷  ─┼┤
│        ├── stocks_4536-T_1d_2008.csv   ◎      ││
│        ├── stocks_4536-T_1d_2009.csv   ◎      ││
│        ├── stocks_4536-T_1d_2010.csv   ◎      ││
│        ├── stocks_4536-T_1d_2011.csv   ◎      ││
│        ├── stocks_4536-T_1d_2012.csv   ◎      ││
│        ├── stocks_4536-T_1d_2013.csv   ◎      ││
│        ├── stocks_4536-T_1d_2014.csv   ◎      ││
│        ├── stocks_4536-T_1d_2015.csv   ◎      ││
│        ├── stocks_4536-T_1d_2016.csv   ◎      ││
│        ├── stocks_4536-T_1d_2017.csv   ◎      ││
│        └── stocks_4536-T.csv           ◎      ││
└── iris                                          ││
     ├── iris_test.csv        ⇦=─────────┘│
     ├── iris_training.csv    ⇦=──────────┘
     ├── pqsDNN.py                        ◆①
     ├── pqsTfLearn.py                    ◆①
     └── pqs.py                           ◆①
```

### readCsv2.py: Load the dataset and generate the intermediate data of step 1 <读入 原始数据(◎)，生成 加工数据(■Ⅰ)>
  * E.g.

  ```
  $ python readCsc2.py 1570 (※stock code)
  ```

### writeCsv2.py: Load step 1 data and generate the intermediate data of step 2 <读入 加工数据(■Ⅰ)，生成 加工数据(■Ⅱ)>
  * E.g.

  ```
  $ python writeCsv2.py 1570
  ```

  * internal parameters(内部参数)
- dim = 40：input the number of dimensions(输入数据维数)
- ma  = 5 ：moving average for weighting close price by the daily volume(成交量加权 5 日 Close 均价)
- p   = 3 ：days before target date for comparison<前 3 天（用于计算 Close 均价）>
- q   = 3 ：days after target date for comparison<偏移位置开始后 3 天（用于计算 Close 均价）>
- offset = 1: offset of predicting after target date(远期预测 偏移)

  * Explanation for internal parameters(参数解释)

   ```
   assume today is 2017/01/19 (before 9am) <假设今日：2017/01/19 （9am 之前）>
   P = 3：【2017/01/16，2017/01/17，2017/01/18】
       use these 3 days average of close prices as comparison condition(3日的Close 均价)

   Offset = 1 : 【2017/01/19】skip ONE day (略过)

   Q = 3：【2017/01/20， 2017/01/23， 2017/01/24】
       targetting on the price trend probability within these 3 days(此三天的价格趋势)
    # 【2017/01/21，2017/01/22】are holidays (休日)
   ```

### tfCsv2.py: Load step 2 data and divide it as 80% training, 20% validating<读入 加工数据(■Ⅱ)，按 二八 比例生成 检证用目标数据(★❶) + 训练用目标数据(★❷)>
  * E.g.

  ```
  $ python tfCsv2.py 1570
  ```

  * internal parameter(内部参数)
- dim = 40：input the number of dimensions(输入数据维数)

### pqs.py: Load data and start both training and validating <读入 检证用目标数据(★❶) + 训练用目标数据(★❷)>
  * References (参考)：
- [Deep Neural Network Classifier](https://www.tensorflow.org/tutorials/tflearn/).
- [Convolutional Network (MNIST)](http://tflearn.org/examples/).
- [Multi-layer perceptron (MNIST)](http://tensorlayer.readthedocs.io/en/latest/user/example.html#basics).
  * E.g.

  ```
  $ cd iris
  $ python pqs.py 1570
  ```

  * internal parameters(内部参数)
- dimension=40：input the number of dimensions(输入数据维数)
- classes=3 ：three sub-classifiers in the trend range areas as: _[0 - decline] < -3.0% < [1 - confused] < +3.5% < [2 - rise]_

### **start.sh**: auto script (自动执行脚本)
  * E.g.

  ```
  $ ./start.sh 1570
  ```

## Dataset (数据源 - ※ k-db site's stopped providing the service till 2017/12/31 ...)

- http://k-db.com/stocks/4536-T/1d/2011?download=csv
- http://k-db.com/stocks/4536-T/1d/2012?download=csv
- ...
- http://k-db.com/stocks/1570-T/1d/2013?download=csv
- http://k-db.com/stocks/1570-T/1d/2014?download=csv
- http://k-db.com/stocks/1570-T/1d/2015?download=csv
- http://k-db.com/stocks/1570-T/1d/2016?download=csv
- http://k-db.com/stocks/1570-T/1d/2017?download=csv
- http://k-db.com/stocks/1570-T?download=csv


## Perform Result (执行结果)
  * 4536 (sample of 81 input dimensions):

  ```
  $ ./start.sh  4536
  ...
  Instructions for updating:
  Estimator is decoupled from Scikit Learn interface by moving into
  separate class SKCompat. Arguments x, y and batch_size are only
  available in the SKCompat class, Estimator will only accept input_fn.
  Example conversion:
    est = Estimator(...) -> est = SKCompat(Estimator(...))
  Accuracy: 0.847059
  WARNING:tensorflow:From /usr/local/lib/python2.7/dist-packages/tensorflow/contrib/learn/python/learn/estimators/dnn.py:348 in predict.: calling predict (from tensorflow.contrib.learn.python.learn.estimators.estimator) with x is deprecated  and will be removed after 2016-12-01.
  ...
  Example conversion:
    est = Estimator(...) -> est = SKCompat(Estimator(...))
  WARNING:tensorflow:float64 is not supported by many models, consider casting to float32.
  Predictions: [1, 1, 1] ⇒ [(2017/01/18-01/20), (2017/01/17-01/19), (2017/01/16-01/18)]
  Refer to base CLOSE prices: [([0]1363 [1] 1406 [1] 1455[2]), ([0]1390 [1] 1433 [1] 1483[2]), ([0]1398 [1] 1442 [1] 1492[2])]
  ```

## TODO
1. Reconstruct network (网络重建)
2. Tuning parameters (参数调整)
3. Strengthen the evaluation and make it visual(增加评估及可视性)
4. Crawl yahoo financial site and compose stocks' latest csv prices dataset(从 yahoo 抓数据整理成 csv数据源)
