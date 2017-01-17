from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import tensorflow as tf
import numpy as np

# Data sets
IRIS_TRAINING = "iris_training.csv"
IRIS_TEST = "iris_test.csv"

# Load datasets.
training_set = tf.contrib.learn.datasets.base.load_csv_with_header(
    filename=IRIS_TRAINING,
    target_dtype=np.int,
    features_dtype=np.float32)
test_set = tf.contrib.learn.datasets.base.load_csv_with_header(
    filename=IRIS_TEST,
    target_dtype=np.int,
    features_dtype=np.float32)

# Specify that all features have real-value data
feature_columns = [tf.contrib.layers.real_valued_column("", dimension=40)]

# Build 3 layer DNN with 10, 20, 10 units respectively.
classifier = tf.contrib.learn.DNNClassifier(feature_columns=feature_columns,
                                            hidden_units=[10, 20, 10],
                                            n_classes=5,
                                            model_dir="/tmp/iris_model")

# Fit model.
classifier.fit(x=training_set.data,
               y=training_set.target,
               steps=2000)

# Evaluate accuracy.
accuracy_score = classifier.evaluate(x=test_set.data,
                                     y=test_set.target)["accuracy"]
print('Accuracy: {0:f}'.format(accuracy_score))

# Classify two new flower samples.
new_samples = np.array(
   [
      [11717.1, 11787.9, 12226.4, 12443.2, 12598.0, 12725.2, 12885.1, 13054.4, 13159.1, 13230.2, 13286.3, 13444.9, 13452.9, 13431.7, 13457.3, 13481.2, 13551.6, 13644.8, 13895.9, 14089.8, 14278.7, 14468.6, 14610.2, 14721.5, 14789.4, 14884.3, 14910.6, 14950.4, 14956.5, 14976.1, 14893.1, 14756.6, 14818.5, 14884.8, 14890.1, 14878.2, 14926.4, 14898.9, 14833.5, 14720.8] ,
      [11666.4, 11717.1, 11787.9, 12226.4, 12443.2, 12598.0, 12725.2, 12885.1, 13054.4, 13159.1, 13230.2, 13286.3, 13444.9, 13452.9, 13431.7, 13457.3, 13481.2, 13551.6, 13644.8, 13895.9, 14089.8, 14278.7, 14468.6, 14610.2, 14721.5, 14789.4, 14884.3, 14910.6, 14950.4, 14956.5, 14976.1, 14893.1, 14756.6, 14818.5, 14884.8, 14890.1, 14878.2, 14926.4, 14898.9, 14833.5] ,
      [11565.3, 11666.4, 11717.1, 11787.9, 12226.4, 12443.2, 12598.0, 12725.2, 12885.1, 13054.4, 13159.1, 13230.2, 13286.3, 13444.9, 13452.9, 13431.7, 13457.3, 13481.2, 13551.6, 13644.8, 13895.9, 14089.8, 14278.7, 14468.6, 14610.2, 14721.5, 14789.4, 14884.3, 14910.6, 14950.4, 14956.5, 14976.1, 14893.1, 14756.6, 14818.5, 14884.8, 14890.1, 14878.2, 14926.4, 14898.9] ,
      [11507.0, 11565.3, 11666.4, 11717.1, 11787.9, 12226.4, 12443.2, 12598.0, 12725.2, 12885.1, 13054.4, 13159.1, 13230.2, 13286.3, 13444.9, 13452.9, 13431.7, 13457.3, 13481.2, 13551.6, 13644.8, 13895.9, 14089.8, 14278.7, 14468.6, 14610.2, 14721.5, 14789.4, 14884.3, 14910.6, 14950.4, 14956.5, 14976.1, 14893.1, 14756.6, 14818.5, 14884.8, 14890.1, 14878.2, 14926.4] ,
      [11497.0, 11507.0, 11565.3, 11666.4, 11717.1, 11787.9, 12226.4, 12443.2, 12598.0, 12725.2, 12885.1, 13054.4, 13159.1, 13230.2, 13286.3, 13444.9, 13452.9, 13431.7, 13457.3, 13481.2, 13551.6, 13644.8, 13895.9, 14089.8, 14278.7, 14468.6, 14610.2, 14721.5, 14789.4, 14884.3, 14910.6, 14950.4, 14956.5, 14976.1, 14893.1, 14756.6, 14818.5, 14884.8, 14890.1, 14878.2] 
   ],
   dtype=float)
#    [[6.4, 3.2, 4.5, 1.5], [5.8, 3.1, 5.0, 1.7]], dtype=float)
y = list(classifier.predict(new_samples, as_iterable=True))
print('Predictions: {}'.format(str(y)))

