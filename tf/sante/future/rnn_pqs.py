# Recurrent Neural Network

# Part 1 - Data Preprocessing

# Importing the libraries
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

import os
import sys
from rd_conf import loadConf
from pathlib import Path

# sys.path.append(Path('.'))
sys.path.append(os.path.dirname(__file__))

# load config parameters
conf = loadConf('./conf/pqsConfig.json')
seqN = conf['seqN']
epochsVal = conf['epochs']
bs = conf['batchSize']

# Importing the training set
dataset_train = pd.read_csv('datasets/japan-225-futures-trend-trn.csv', encoding="UTF-8",
                            header=None, names=['time', 'trend', 'price'])
trn_sz = dataset_train.shape[0]
training_set = dataset_train.iloc[:, 2:3].values

# Feature Scaling
from sklearn.preprocessing import MinMaxScaler

sc = MinMaxScaler(feature_range=(0, 1))
training_set_scaled = sc.fit_transform(training_set)

# Creating a data structure with 60 timesteps and 1 output
X_train = []
y_train = []
for i in range(seqN, trn_sz - 1):
    X_train.append(training_set_scaled[i - seqN:i, 0])
    y_train.append(training_set_scaled[i, 0])
X_train, y_train = np.array(X_train), np.array(y_train)

# Reshaping
X_train = np.reshape(X_train, (X_train.shape[0], X_train.shape[1], 1))

# Part 2 - Building the RNN

# Importing Tensorflow
import tensorflow as tf

# Initialising the RNN
regressor = tf.keras.models.Sequential()

# Adding the first LSTM layer and some Dropout regularisation
regressor.add(tf.keras.layers.LSTM(units=50, return_sequences=True, input_shape=(X_train.shape[1], 1)))
regressor.add(tf.keras.layers.Dropout(0.2))

# Adding a second LSTM layer and some Dropout regularisation
regressor.add(tf.keras.layers.LSTM(units=50, return_sequences=True))
regressor.add(tf.keras.layers.Dropout(0.2))

# Adding a third LSTM layer and some Dropout regularisation
regressor.add(tf.keras.layers.LSTM(units=50, return_sequences=True))
regressor.add(tf.keras.layers.Dropout(0.2))

# Adding a fourth LSTM layer and some Dropout regularisation
regressor.add(tf.keras.layers.LSTM(units=50))
regressor.add(tf.keras.layers.Dropout(0.2))

# Adding the output layer
regressor.add(tf.keras.layers.Dense(units=1))

# Compiling the RNN
regressor.compile(optimizer='adam', loss='mean_squared_error')

# Fitting the RNN to the Training set
regressor.fit(X_train, y_train, epochs=epochsVal, batch_size=bs)

# Part 3 - Making the predictions and visualising the results

# Getting the real stock price of 2017
dataset_test = pd.read_csv('datasets/japan-225-futures-trend-tst.csv', encoding="UTF-8",
                           header=None, names=['time', 'trend', 'price'])
tst_sz = dataset_test.shape[0]
real_stock_price = dataset_test.iloc[:, 2:3].values

# Getting the predicted stock price of 2017
dataset_total = pd.concat((dataset_train['price'], dataset_test['price']), axis=0)
inputs = dataset_total[len(dataset_total) - len(dataset_test) - seqN:].values
inputs = inputs.reshape(-1, 1)
inputs = sc.transform(inputs)
X_test = []
for i in range(seqN, seqN+tst_sz):
    X_test.append(inputs[i - seqN:i, 0])
X_test = np.array(X_test)
X_test = np.reshape(X_test, (X_test.shape[0], X_test.shape[1], 1))
predicted_stock_price = regressor.predict(X_test)
predicted_stock_price = sc.inverse_transform(predicted_stock_price)

# Visualising the results
plt.plot(real_stock_price, color='red', label='Real Nikkei 225 Future Price')
plt.plot(predicted_stock_price, color='blue', label='Predicted Nikkei 225 Future Price')
plt.title('Nikkei 225 Future Price Prediction')
plt.xlabel('Time')
plt.ylabel('Nikkei 225 Future Price')
plt.legend()
# plt.show()

# env MPLBACKEND=Agg
plt.savefig("test.png")
