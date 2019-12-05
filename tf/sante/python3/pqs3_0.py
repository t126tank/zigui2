#! /usr/bin/python3
# -*- coding: utf8 -*-

# https://raw.githubusercontent.com/tensorlayer/tensorlayer/master/examples/basic_tutorials/tutorial_mnist_simple.py
# https://raw.githubusercontent.com/tensorlayer/tensorlayer/master/examples/text_generation/tutorial_generate_text.py
# https://github.com/tensorlayer/tensorlayer/issues/12#issuecomment-271084773
# https://www.jb51.net/article/134956.htm
# https://www.jianshu.com/p/300b462a11c2

import tensorflow as tf
import tensorlayer as tl
import datetime
import numpy as np
import json
import sys
import os.path
import shutil
from pathlib import Path
sys.path.append(str(Path('.').resolve().parent))
print(sys.path)
from confCsv3 import *


tf.logging.set_verbosity(tf.logging.DEBUG)
tl.logging.set_verbosity(tl.logging.DEBUG)

def main(argv):
   code = "1301"
   train = False

   if len(argv) != 0:
      code = argv[0]
      if len(argv) > 1:
         train = True

   pqsConf = loadConf('../pqsConf.json')
   dim     = pqsConf['dim']
   dim2    = dim ** 2
   n_cls   = pqsConf['n_cls']
   inepoch = pqsConf['n_epoch']

   INPUT_RECORD  = "input.csv"

   # though its name is "test", to be used for the evaluation
   IRIS_TEST     = "iris_test.csv"
   # Read in test csv's where there are 7*7 features and a target
   csvTest = np.genfromtxt(IRIS_TEST, delimiter=",", skip_header=1)
   X_test = np.array(csvTest[:, :dim2])
   y_test = csvTest[:,dim2]

   IRIS_TRAINING = "iris_training.csv"

   # Data loading and preprocessing
   # Read in train csv's where there are 7*7 features and a target
   csvTrain = np.genfromtxt(IRIS_TRAINING, delimiter=",", skip_header=1)
   X_train = np.array(csvTrain[:, :dim2])
   y_train = csvTrain[:,dim2]

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
   with tf.name_scope('input'):
      x = tf.placeholder(tf.float32, shape=[None, dim2], name='x')
      y_ = tf.placeholder(tf.int64, shape=[None, ], name='y_')

   with tf.name_scope('input_reshape'):
      image_shaped_input = tf.reshape(x, [-1, dim, dim, 1])
      tf.summary.image('input', image_shaped_input, 2)

   path0 = '../stocks/' + code + '/out/'
   npzPath = path0 + code + '.npz'

   sess = tf.InteractiveSession()

   # initialize all variables in the session
   # tl.layers.initialize_global_variables(sess)
   # init = tf.global_variables_initializer()

   # define the network
   network = tl.layers.InputLayer(x, name='input_layer')
   network = tl.layers.DropoutLayer(network, keep=0.8, name='drop1')
   network = tl.layers.DenseLayer(network, n_units=800,
                                   act = tf.nn.relu, name='relu1')
   network = tl.layers.DropoutLayer(network, keep=0.5, name='drop2')
   network = tl.layers.DenseLayer(network, n_units=800,
                                   act = tf.nn.relu, name='relu2')
   '''
   network = tl.layers.DropoutLayer(network, keep=0.8, name='drop3')
   network = tl.layers.DenseLayer(network, n_units=800,
                                   act = tf.nn.relu, name='relu3')
   network = tl.layers.DropoutLayer(network, keep=0.8, name='drop4')
   network = tl.layers.DenseLayer(network, n_units=800,
                                   act = tf.nn.relu, name='relu4')
   network = tl.layers.DropoutLayer(network, keep=0.8, name='drop5')
   network = tl.layers.DenseLayer(network, n_units=800,
                                   act = tf.nn.relu, name='relu5')
   '''
   network = tl.layers.DropoutLayer(network, keep=0.5, name='drop6')
   # the softmax is implemented internally in tl.cost.cross_entropy(y, y_) to
   # speed up computation, so we use identity here.
   # see tf.nn.sparse_softmax_cross_entropy_with_logits()
   network = tl.layers.DenseLayer(network, n_units=n_cls,
                                  act = tf.identity,
                                  name='output_layer')

   # define cost function and metric.
   y = network.outputs
   cost = tl.cost.cross_entropy(y, y_, 'cost')
   correct_prediction = tf.equal(tf.argmax(y, 1), y_)
   acc = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))
   y_op = tf.argmax(tf.nn.softmax(y), 1)

   # <code>.npz exists and to use it directly
   if os.path.isfile(npzPath) and not train:
      tl.files.load_and_assign_npz(sess=sess, name=npzPath, network=network)
   else:
      # define the optimizer
      train_params = network.all_params
      train_op = tf.train.AdamOptimizer(learning_rate=0.0001, beta1=0.9, beta2=0.999,
                                        epsilon=1e-08, use_locking=False).minimize(cost, var_list=train_params)

      # https://tensorlayer.readthedocs.io/en/stable/_modules/tensorlayer/layers/utils.html#initialize_global_variables
      # http://mosapro.hatenablog.com/entry/2017/05/17/094606

      sess.run(tf.global_variables_initializer())

      # print network information
      network.print_params()
      network.print_layers()

      # train the network
      # http://tensorlayer.readthedocs.io/en/latest/modules/utils.html
      tl.utils.fit(sess, network, train_op, cost, X_train, y_train, x, y_,
                  acc=acc, batch_size=50, n_epoch=inepoch, print_freq=111,
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
   # Read in
   with open(path0 + 'item.json') as infile:
      item = json.load(infile)

   item['possibility'] = round(test_acc, 6)
   item['result'] = int(result[0])

   # Write out
   with open(path0 + 'item.json', 'w') as outfile:
      json.dump(item, outfile)

   # Backup
   if train:
      tm = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
      fn = 'item_' + tm + '.json'
      shutil.copy(path0 + 'item.json', path0 + 'history/' + fn)


if __name__ == "__main__":
   main(sys.argv[1:])


# Ref: http://qiita.com/akasakas/items/fad4ca279c9a726998e0
