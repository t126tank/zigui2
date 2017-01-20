#! /usr/bin/python
# -*- coding: utf8 -*-

# https://raw.githubusercontent.com/zsdonghao/tensorlayer/master/example/tutorial_mnist_simple.py

import tensorflow as tf
import tensorlayer as tl
import numpy as np

sess = tf.InteractiveSession()

IRIS_TRAINING = "iris_training.csv"
IRIS_TEST = "iris_test.csv"

# Data loading and preprocessing
# Read in train and test csv's where there are 81 features and a target
csvTrain = np.genfromtxt(IRIS_TRAINING, delimiter=",", skip_header=1)
X_train = np.array(csvTrain[:, :81])
y_train = csvTrain[:,81]

csvTest = np.genfromtxt(IRIS_TEST, delimiter=",", skip_header=1)
X_test = np.array(csvTest[:, :81])
y_test = csvTest[:,81]

# X_train = X_train.reshape([-1,7,7,1])
# X_test = X_test.reshape([-1,7,7,1])

# reshape Y and Y_test to have shape (batch_size, 1).
# y_train = y_train.reshape([-1, 28, 28, 1])
# y_test = y_test.reshape([-1, 28, 28, 1])

# X_val=[]
# X_val=np.array(X_val)

# y_val=[]
# y_val=np.array(y_val)


### Ori ###
# prepare data
# X_train, y_train, X_val, y_val, X_test, y_test = \
#                                tl.files.load_mnist_dataset(shape=(-1,784))
###########

# define placeholder
x = tf.placeholder(tf.float32, shape=[None, 81], name='x')
y_ = tf.placeholder(tf.int64, shape=[None, ], name='y_')

# define the network
network = tl.layers.InputLayer(x, name='input_layer')
network = tl.layers.DropoutLayer(network, keep=0.8, name='drop1')
network = tl.layers.DenseLayer(network, n_units=800,
                                act = tf.nn.relu, name='relu1')
network = tl.layers.DropoutLayer(network, keep=0.5, name='drop2')
network = tl.layers.DenseLayer(network, n_units=800,
                                act = tf.nn.relu, name='relu2')
network = tl.layers.DropoutLayer(network, keep=0.5, name='drop3')
# the softmax is implemented internally in tl.cost.cross_entropy(y, y_) to
# speed up computation, so we use identity here.
# see tf.nn.sparse_softmax_cross_entropy_with_logits()
network = tl.layers.DenseLayer(network, n_units=3,
                                act = tf.identity,
                                name='output_layer')

# define cost function and metric.
y = network.outputs
cost = tl.cost.cross_entropy(y, y_)
correct_prediction = tf.equal(tf.argmax(y, 1), y_)
acc = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))
y_op = tf.argmax(tf.nn.softmax(y), 1)

# define the optimizer
train_params = network.all_params
train_op = tf.train.AdamOptimizer(learning_rate=0.0001, beta1=0.9, beta2=0.999,
                            epsilon=1e-08, use_locking=False).minimize(cost, var_list=train_params)

# initialize all variables in the session
tl.layers.initialize_global_variables(sess)

# print network information
network.print_params()
network.print_layers()

# train the network
# http://tensorlayer.readthedocs.io/en/latest/modules/utils.html
tl.utils.fit(sess, network, train_op, cost, X_train, y_train, x, y_,
            acc=acc, batch_size=50, n_epoch=500, print_freq=1,
            eval_train=False)
#           X_val=X_val, y_val=y_val, eval_train=False)

# evaluation
tl.utils.test(sess, network, acc, X_test, y_test, x, y_, batch_size=None, cost=cost)

# save the network to .npz file
tl.files.save_npz(network.all_params , name='model.npz')

# predict

new_samples = np.array(
   [
[1408.1, 1421.3, 1429.8, 1436.4, 1447.5, 1456.8, 1469.8, 1483.6, 1495.7, 1491.4, 1491.6, 1495.1, 1501.2, 1503.8, 1514.3, 1517.5, 1515.1, 1511.4, 1509.7, 1503.2, 1505.6, 1513.6, 1517.3, 1517.3, 1516.9, 1513.9, 1507.8, 1503.9, 1506.5, 1515.1, 1518.6, 1514.1, 1492.4, 1477.6, 1461.4, 1442.3, 1442.6, 1458.8, 1465.1, 1476.8, 1504.0, 1513.1, 1510.6, 1515.4, 1516.2, 1501.7, 1491.7, 1488.0, 1472.3, 1429.9, 1418.3, 1401.0, 1384.3, 1369.5, 1343.6, 1312.9, 1294.8, 1292.6, 1296.6, 1306.5, 1330.9, 1353.3, 1371.1, 1384.6, 1395.0, 1401.9, 1410.5, 1415.3, 1415.2, 1413.8, 1416.8, 1420.6, 1427.3, 1438.5, 1458.9, 1469.5, 1470.7, 1470.3, 1466.6, 1448.7, 1422.2] ,
[1394.9, 1408.1, 1421.3, 1429.8, 1436.4, 1447.5, 1456.8, 1469.8, 1483.6, 1495.7, 1491.4, 1491.6, 1495.1, 1501.2, 1503.8, 1514.3, 1517.5, 1515.1, 1511.4, 1509.7, 1503.2, 1505.6, 1513.6, 1517.3, 1517.3, 1516.9, 1513.9, 1507.8, 1503.9, 1506.5, 1515.1, 1518.6, 1514.1, 1492.4, 1477.6, 1461.4, 1442.3, 1442.6, 1458.8, 1465.1, 1476.8, 1504.0, 1513.1, 1510.6, 1515.4, 1516.2, 1501.7, 1491.7, 1488.0, 1472.3, 1429.9, 1418.3, 1401.0, 1384.3, 1369.5, 1343.6, 1312.9, 1294.8, 1292.6, 1296.6, 1306.5, 1330.9, 1353.3, 1371.1, 1384.6, 1395.0, 1401.9, 1410.5, 1415.3, 1415.2, 1413.8, 1416.8, 1420.6, 1427.3, 1438.5, 1458.9, 1469.5, 1470.7, 1470.3, 1466.6, 1448.7] ,
[1381.0, 1394.9, 1408.1, 1421.3, 1429.8, 1436.4, 1447.5, 1456.8, 1469.8, 1483.6, 1495.7, 1491.4, 1491.6, 1495.1, 1501.2, 1503.8, 1514.3, 1517.5, 1515.1, 1511.4, 1509.7, 1503.2, 1505.6, 1513.6, 1517.3, 1517.3, 1516.9, 1513.9, 1507.8, 1503.9, 1506.5, 1515.1, 1518.6, 1514.1, 1492.4, 1477.6, 1461.4, 1442.3, 1442.6, 1458.8, 1465.1, 1476.8, 1504.0, 1513.1, 1510.6, 1515.4, 1516.2, 1501.7, 1491.7, 1488.0, 1472.3, 1429.9, 1418.3, 1401.0, 1384.3, 1369.5, 1343.6, 1312.9, 1294.8, 1292.6, 1296.6, 1306.5, 1330.9, 1353.3, 1371.1, 1384.6, 1395.0, 1401.9, 1410.5, 1415.3, 1415.2, 1413.8, 1416.8, 1420.6, 1427.3, 1438.5, 1458.9, 1469.5, 1470.7, 1470.3, 1466.6] 
   ],
   dtype=float)

print(tl.utils.predict(sess, network, new_samples, x, y_op))

sess.close()
