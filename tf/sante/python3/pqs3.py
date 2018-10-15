#! /usr/bin/python3
# -*- coding: utf8 -*-

# https://raw.githubusercontent.com/tensorlayer/tensorlayer/master/examples/basic_tutorials/tutorial_mnist_simple.py
# https://raw.githubusercontent.com/tensorlayer/tensorlayer/master/examples/text_generation/tutorial_generate_text.py
# https://github.com/tensorlayer/tensorlayer/issues/12#issuecomment-271084773

import tensorflow as tf
import tensorlayer as tl
import numpy as np
import json
import sys
import os.path

def main(argv):
   code = "1301"
   train = False

   if len(argv) != 0:
      code = argv[0]
      if len(argv) > 1:
         train = True

   n_cls         = 2
   INPUT_RECORD  = "input.csv"

   # though its name is "test", to be used for the evaluation
   IRIS_TEST     = "iris_test.csv"
   # Read in test csv's where there are 81 features and a target
   csvTest = np.genfromtxt(IRIS_TEST, delimiter=",", skip_header=1)
   X_test = np.array(csvTest[:, :81])
   y_test = csvTest[:,81]

   IRIS_TRAINING = "iris_training.csv"

   # Data loading and preprocessing
   # Read in train csv's where there are 81 features and a target
   csvTrain = np.genfromtxt(IRIS_TRAINING, delimiter=",", skip_header=1)
   X_train = np.array(csvTrain[:, :81])
   y_train = csvTrain[:,81]

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

   path0 = '../stocks/' + code + '/out/'
   npzPath = path0 + code + '.npz'

   sess = tf.InteractiveSession()

   # initialize all variables in the session
   tl.layers.initialize_global_variables(sess)

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
   network = tl.layers.DenseLayer(network, n_units=n_cls,
                                  act = tf.identity,
                                  name='output_layer')

   # <code>.npz exists and to use it directly
   if os.path.isfile(npzPath) and not train:
      tl.files.load_and_assign_npz(sess=sess, name=npzPath, network=network)
   else:
      # define cost function and metric.
      y = network.outputs
      cost = tl.cost.cross_entropy(y, y_, 'cost')
      correct_prediction = tf.equal(tf.argmax(y, 1), y_)
      acc = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))
      y_op = tf.argmax(tf.nn.softmax(y), 1)

      # define the optimizer
      train_params = network.all_params
      train_op = tf.train.AdamOptimizer(learning_rate=0.0001, beta1=0.9, beta2=0.999,
                                        epsilon=1e-08, use_locking=False).minimize(cost, var_list=train_params)

      # print network information
      # network.print_params()
      # network.print_layers()

      # train the network
      # http://tensorlayer.readthedocs.io/en/latest/modules/utils.html
      tl.utils.fit(sess, network, train_op, cost, X_train, y_train, x, y_,
                  acc=acc, batch_size=100, n_epoch=333, print_freq=50,
                  eval_train=True)
      #           X_val=X_val, y_val=y_val, eval_train=False)


   # evaluation
   # test_acc = tl.utils.test(sess, network, acc, X_test, y_test, x, y_, batch_size=None, cost=cost)
   #### https://tensorlayer.readthedocs.io/en/1.3.0/_modules/tensorlayer/utils.html#test
   #### /usr/local/lib/python2.7/dist-packages/tensorlayer/utils.py - if needs patching

   y_predict = tl.utils.predict(sess, network, X_test, x, y_op)
   c_mat, f1, test_acc, f1_macro = tl.utils.evaluation(y_test=y_test, y_predict=y_predict, n_classes=n_cls)

   # save the network to .npz file
   tl.files.save_npz(network.all_params , name=npzPath)

   # predict
   new_samples = []
   inRecord = np.genfromtxt(INPUT_RECORD, delimiter=",")
   new_samples.append(inRecord)

   result = tl.utils.predict(sess, network, new_samples, x, y_op)

   sess.close()

   # For report
   item = {}
   item['possibility'] = test_acc
   item['result'] = int(result[0])

   with open(path0 + 'item.json', 'w') as outfile:
      json.dump(item, outfile)


if __name__ == "__main__":
   main(sys.argv[1:])


# Ref: http://qiita.com/akasakas/items/fad4ca279c9a726998e0

