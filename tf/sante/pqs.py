#! /usr/bin/python
# -*- coding: utf8 -*-

# https://raw.githubusercontent.com/zsdonghao/tensorlayer/master/example/tutorial_mnist_simple.py

import tensorflow as tf
import tensorlayer as tl
import numpy as np
import json
import sys

def main(argv):
   code = "1301"
   if len(argv) != 0:
      code = argv[0]

   sess = tf.InteractiveSession()

   n_classes = 3
   IRIS_TRAINING = "iris_training.csv"
   IRIS_TEST = "iris_test.csv"
   INPUT_RECORD  = "input.csv"

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
   network = tl.layers.DenseLayer(network, n_units=n_classes,
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
   # network.print_params()
   # network.print_layers()

   # train the network
   # http://tensorlayer.readthedocs.io/en/latest/modules/utils.html
   tl.utils.fit(sess, network, train_op, cost, X_train, y_train, x, y_,
               acc=acc, batch_size=100, n_epoch=50, print_freq=1,
               eval_train=True)
   #           X_val=X_val, y_val=y_val, eval_train=False)

   # evaluation
   tl.utils.test(sess, network, acc, X_test, y_test, x, y_, batch_size=None, cost=cost)
   # c_mat, f1, acc, f1_macro = tl.utils.evaluation(y_test, y_, n_classes)

   # save the network to .npz file
   tl.files.save_npz(network.all_params , name='model.npz')

   # predict
   new_samples = []
   inRecord = np.genfromtxt(INPUT_RECORD, delimiter=",")
   new_samples.append(inRecord)

   result = tl.utils.predict(sess, network, new_samples, x, y_op)

   # For report
   f = open('../stocks/' + code + '/out/item.json', 'a')
   print >> f, '"possibility": %f, "result": %d' % (0.8, result[0])
   f.close()

   sess.close()


if __name__ == "__main__":
   main(sys.argv[1:])

