# -*- coding: utf-8 -*-

""" Convolutional Neural Network for MNIST dataset classification task.

References:
    Y. LeCun, L. Bottou, Y. Bengio, and P. Haffner. "Gradient-based
    learning applied to document recognition." Proceedings of the IEEE,
    86(11):2278-2324, November 1998.

Links:
    [MNIST Dataset] http://yann.lecun.com/exdb/mnist/

"""

from __future__ import division, print_function, absolute_import

import tflearn
from tflearn.layers.core import input_data, dropout, fully_connected
from tflearn.layers.conv import conv_2d, max_pool_2d
from tflearn.layers.normalization import local_response_normalization
from tflearn.layers.estimator import regression

import numpy as np
import tensorflow as tf

IRIS_TRAINING = "iris_training.csv"
IRIS_TEST = "iris_test.csv"

# Data loading and preprocessing
# Read in train and test csv's where there are 49 features and a target
csvTrain = np.genfromtxt(IRIS_TRAINING, delimiter=",", skip_header=1)
X = np.array(csvTrain[:, :49])
Y = csvTrain[:,49]

csvTest = np.genfromtxt(IRIS_TEST, delimiter=",", skip_header=1)
testX = np.array(csvTest[:, :49])
testY = csvTest[:,49]

X = X.reshape([-1,7,7,1])
testX = testX.reshape([-1,7,7,1])

# reshape Y and Y_test to have shape (batch_size, 1).
# Y = Y.reshape([-1, 28, 28, 1])
# testY = testY.reshape([-1, 28, 28, 1])

## Building convolutional network
network = input_data(shape=[None, 7, 7, 1], name='input')
network = conv_2d(network, 32, 3, activation='relu', regularizer="L2")
network = max_pool_2d(network, 2)
network = local_response_normalization(network)
network = conv_2d(network, 64, 3, activation='relu', regularizer="L2")
network = max_pool_2d(network, 2)
network = local_response_normalization(network)
network = fully_connected(network, 128, activation='tanh')
network = dropout(network, 0.8)
network = fully_connected(network, 256, activation='tanh')
network = dropout(network, 0.8)
# network = fully_connected(network, 10, activation='softmax')       # output size
# network = fully_connected(network, 1, activation='linear')
network = regression(network, optimizer='adam', learning_rate=0.01,
                     loss='categorical_crossentropy', name='target') # loss='mean_square'

### add this "fix":
col = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES)
for x in col:
    tf.add_to_collection(tf.GraphKeys.VARIABLES, x )    
## then continue:

# Training
model = tflearn.DNN(network, tensorboard_verbose=0)
model.fit({'input': X}, {'target': Y}, n_epoch=20,
           validation_set=({'input': testX}, {'target': testY}),
           snapshot_step=100, show_metric=True)                      # run_id='convnet_mnist'

# Ref: http://stackoverflow.com/questions/37433321/tensorflow-tflearn-valueerror-cannot-feed-value-of-shape-64-for-tensor-uta
