#!/usr/bin/python
# coding: utf-8

from __future__ import print_function

import datetime
import json
import re
import sys
import time
import urllib2
from bs4 import BeautifulSoup

BASE_URL = "https://monex.ifis.co.jp/"
PNG_DIR  = "png/"
LAT_DIR  = "latest/"

all_stocks = [1301, 1332, 1333, 1352, 1376, 1377, 1379, 1384, 1414, 1417, 1419, 1420, 1430, 1433, 1435, 1514, 1515, 1518, 1605, 1606, 1662, 1663, 1712, 1716, 1719, 1720, 1721, 1722, 1726, 1762, 1766, 1768, 1780, 1801, 1802, 1803, 1805, 1808, 1810, 1811, 1812, 1813, 1814, 1815, 1820, 1821, 1822, 1824, 1826, 1827, 1833, 1835, 1847, 1852, 1860, 1861, 1865, 1866, 1867, 1868, 1870, 1871, 1873, 1878, 1879, 1881, 1882, 1883, 1884, 1885, 1888, 1890, 1893, 1898, 1899, 1909, 1911, 1914, 1916, 1919, 1921, 1925, 1926, 1928, 1929, 1930, 1934, 1937, 1939, 1941, 1942, 1944, 1945, 1946, 1949, 1950, 1951, 1952, 1954, 1956, 1959, 1961, 1963, 1964, 1967, 1968, 1969, 1972, 1973, 1975, 1976, 1979, 1980, 1982, 1983, 2001, 2002, 2003, 2004, 2009, 2053, 2060, 2107, 2108, 2109, 2112, 2117, 2120, 2124, 2127, 2130, 2139, 2151, 2154, 2157, 2168, 2169, 2170, 2174, 2175, 2181, 2183, 2193, 2196, 2198, 2201, 2204, 2206, 2207, 2209, 2211, 2212, 2215, 2217, 2220, 2222, 2229, 2264, 2266, 2267, 2269, 2270, 2281, 2282, 2286, 2288, 2292, 2296, 2301, 2305, 2309, 2317, 2325, 2326, 2327, 2331, 2335, 2337, 2352, 2353, 2359, 2371, 2372, 2374, 2376, 2378, 2379, 2384, 2389, 2395, 2398, 2410, 2413, 2418, 2424, 2427, 2428, 2429, 2432, 2433, 2440, 2445, 2453, 2461, 2462, 2464, 2475, 2485, 2487, 2491, 2492, 2501, 2502, 2503, 2531, 2533, 2540, 2579, 2587, 2590, 2593, 25935, 2594, 2597, 2599, 2602, 2607, 2612, 2613, 2651, 2659, 2664, 2670, 2674, 2676, 2678, 2681, 2685, 2686, 2687, 2692, 2695, 2698, 2715, 2726, 2729, 2730, 2733, 2734, 2735, 2737, 2742, 2749, 2753, 2760, 2764, 2767, 2768, 2784, 2791, 2792, 2796, 2801, 2802, 2809, 2810, 2811, 2812, 2815, 2818, 2819, 2871, 2874, 2875, 2882, 2883, 2884, 2897, 2899, 2904, 2908, 2910, 2914, 2915, 2918, 2922, 2924, 2925, 2930, 2931, 3001, 3002, 3003, 3004, 3023, 3028, 3030, 3031, 3034, 3036, 3038, 3040, 3046, 3048, 3050, 3053, 3064, 3067, 3073, 3076, 3079, 3082, 3085, 3086, 3087, 3088, 3091, 3092, 3093, 3097, 3098, 3099, 3101, 3103, 3104, 3105, 3106, 3107, 3109, 3110, 3116, 3132, 3134, 3139, 3141, 3148, 3151, 3153, 3154, 3156, 3157, 3159, 3160, 3166, 3167, 3169, 3172, 3173, 3175, 3176, 3178, 3179, 3180, 3183, 3186, 3191, 3193, 3194, 3196, 3197, 3199, 3201, 3202, 3204, 3205, 3221, 3222, 3228, 3230, 3231, 3232, 3244, 3245, 3246, 3250, 3252, 3254, 3258, 3271, 3276, 3277, 3280, 3284, 3288, 3289, 3291, 3294, 3299, 3302, 3313, 3315, 3319, 3321, 3328, 3333, 3341, 3349, 3360, 3361, 3366, 3371, 3376, 3382, 3385, 3387, 3388, 3391, 3392, 3393, 3395, 3396, 3397, 3401, 3402, 3405, 3407, 3408, 3415, 3421, 3431, 3433, 3434, 3436, 3443, 3445, 3454, 3457, 3458, 3465, 3501, 3512, 3513, 3521, 3524, 3526, 3529, 3543, 3544, 3546, 3548, 3549, 3551, 3553, 3563, 3564, 3569, 3571, 3577, 3580, 3591, 3593, 3606, 3607, 3608, 3611, 3626, 3627, 3630, 3632, 3635, 3636, 3639, 3640, 3648, 3649, 3654, 3655, 3656, 3657, 3658, 3659, 3660, 3661, 3662, 3666, 3667, 3668, 3669, 3672, 3673, 3676, 3678, 3681, 3683, 3686, 3687, 3688, 3694, 3696, 3708, 3724, 3738, 3741, 3751, 3756, 3762, 3763, 3765, 3769, 3770, 3771, 3774, 3778, 3784, 3788, 3817, 3822, 3826, 3834, 3835, 3837, 3843, 3844, 3852, 3861, 3863, 3864, 3865, 3877, 3878, 3880, 3896, 3902, 3903, 3909, 3912, 3916, 3918, 3919, 3920, 3926, 3928, 3932, 3937, 3938, 3941, 3946, 3950, 3963, 3964, 3975, 3978, 4004, 4005, 4008, 4021, 4022, 4023, 4025, 4027, 4028, 4031, 4033, 4041, 4042, 4043, 4044, 4045, 4046, 4047, 4061, 4062, 4063, 4064, 4078, 4088, 4091, 4092, 4093, 4095, 4097, 4098, 4099, 4100, 4109, 4112, 4114, 4116, 4118, 4151, 4182, 4183, 4185, 4186, 4187, 4188, 4189, 4202, 4203, 4204, 4205, 4206, 4208, 4212, 4215, 4216, 4217, 4218, 4220, 4221, 4228, 4229, 4231, 4238, 4245, 4246, 4248, 4249, 4272, 4275, 4282, 4284, 4286, 4290, 4295, 4299, 4301, 4307, 4310, 4312, 4318, 4319, 4320, 4321, 4323, 4324, 4326, 4331, 4333, 4337, 4343, 4344, 4345, 4346, 4350, 4362, 4368, 4401, 4403, 4404, 4406, 4410, 4452, 4461, 4463, 4465, 4471, 4502, 4503, 4506, 4507, 4508, 4512, 4514, 4516, 4517, 4519, 4521, 4523, 4526, 4527, 4528, 4530, 4531, 4534, 4536, 4538, 4539, 4540, 4541, 4543, 4544, 4547, 4548, 4549, 4550, 4551, 4552, 4553, 4554, 4555, 4559, 4568, 4569, 4574, 4577, 4578, 4581, 4587, 4611, 4612, 4613, 4615, 4617, 4619, 4620, 4626, 4631, 4633, 4634, 4636, 4641, 4651, 4653, 4658, 4661, 4662, 4665, 4666, 4668, 4671, 4674, 4676, 4678, 4679, 4680, 4681, 4684, 4686, 4687, 4689, 4694, 4696, 4704, 4708, 4709, 4714, 4716, 4718, 4719, 4722, 4725, 4726, 4728, 4732, 4733, 4739, 4743, 4745, 4746, 4751, 4755, 4762, 4763, 4767, 4768, 4775, 4776, 4779, 4801, 4809, 4812, 4819, 4820, 4825, 4826, 4828, 4829, 4839, 4845, 4848, 4901, 4902, 4911, 4912, 4914, 4917, 4919, 4921, 4922, 4923, 4924, 4926, 4927, 4928, 4929, 4951, 4955, 4956, 4958, 4963, 4967, 4968, 4971, 4973, 4974, 4975, 4977, 4979, 4980, 4985, 4992, 4994, 4996, 4997, 5002, 5009, 5011, 5013, 5015, 5017, 5018, 5019, 5020, 5021, 5101, 5105, 5108, 5110, 5121, 5122, 5142, 5185, 5186, 5187, 5191, 5192, 5195, 5201, 5202, 5204, 5208, 5210, 5214, 5218, 5232, 5233, 5261, 5262, 5269, 5273, 5288, 5301, 5302, 5310, 5331, 5332, 5333, 5334, 5337, 5344, 5351, 5352, 5357, 5358, 5363, 5367, 5384, 5391, 5393, 5401, 5406, 5408, 5410, 5411, 5413, 5423, 5440, 5444, 5445, 5449, 5451, 5453, 5463, 5464, 5471, 5476, 5480, 5481, 5482, 5486, 5491, 5541, 5563, 5602, 5603, 5612, 5631, 5632, 5658, 5659, 5702, 5703, 5706, 5707, 5711, 5713, 5714, 5715, 5721, 5726, 5727, 5741, 5801, 5802, 5803, 5805, 5807, 5809, 5815, 5819, 5821, 5851, 5852, 5857, 5901, 5902, 5909, 5911, 5912, 5915, 5923, 5929, 5930, 5932, 5933, 5936, 5938, 5942, 5943, 5946, 5947, 5949, 5951, 5957, 5958, 5959, 5970, 5974, 5975, 5976, 5981, 5985, 5986, 5988, 5989, 5991, 5992, 5998, 6005, 6013, 6028, 6029, 6032, 6036, 6037, 6044, 6047, 6048, 6050, 6054, 6055, 6058, 6059, 6065, 6070, 6071, 6073, 6077, 6078, 6080, 6082, 6083, 6087, 6088, 6089, 6093, 6097, 6098, 6099, 6101, 6103, 6104, 6113, 6118, 6121, 6134, 6135, 6136, 6138, 6140, 6141, 6143, 6146, 6151, 6157, 6165, 6167, 6171, 6178, 6183, 6184, 6186, 6187, 6189, 6191, 6196, 6197, 6199, 6200, 6201, 6203, 6205, 6208, 6210, 6217, 6218, 6222, 6235, 6236, 6238, 6240, 6247, 6250, 6258, 6262, 6268, 6269, 6272, 6273, 6274, 6277, 6278, 6282, 6284, 6287, 6289, 6291, 6293, 6294, 6298, 6301, 6302, 6305, 6306, 6309, 6310, 6315, 6316, 6317, 6319, 6323, 6325, 6326, 6328, 6330, 6331, 6332, 6333, 6335, 6339, 6340, 6345, 6349, 6351, 6355, 6358, 6361, 6362, 6363, 6364, 6366, 6367, 6368, 6369, 6370, 6371, 6373, 6376, 6378, 6379, 6381, 6383, 6387, 6390, 6393, 6395, 6406, 6407, 6409, 6412, 6413, 6417, 6418, 6419, 6420, 6428, 6430, 6432, 6436, 6440, 6444, 6445, 6448, 6454, 6455, 6457, 6458, 6459, 6460, 6461, 6462, 6463, 6464, 6465, 6470, 6471, 6472, 6473, 6474, 6479, 6480, 6481, 6482, 6485, 6486, 6489, 6490, 6498, 6501, 6503, 6504, 6505, 6506, 6507, 6508, 6513, 6516, 6517, 6538, 6539, 6540, 6584, 6586, 6588, 6590, 6592, 6594, 6615, 6617, 6619, 6620, 6622, 6624, 6630, 6632, 6638, 6640, 6641, 6644, 6645, 6651, 6652, 6654, 6674, 6675, 6676, 6678, 6701, 6702, 6703, 6704, 6706, 6707, 6715, 6718, 6723, 6724, 6727, 6728, 6730, 6737, 6740, 6741, 6742, 6744, 6745, 6750, 6752, 6753, 6754, 6755, 6756, 6758, 6762, 6763, 6768, 6770, 6771, 6773, 6779, 6785, 6788, 6789, 6794, 6796, 6798, 6800, 6803, 6804, 6806, 6807, 6809, 6810, 6814, 6815, 6816, 6817, 6820, 6823, 6826, 6839, 6841, 6844, 6845, 6848, 6849, 6850, 6853, 6855, 6856, 6857, 6858, 6859, 6861, 6866, 6869, 6871, 6875, 6877, 6879, 6901, 6902, 6905, 6908, 6911, 6914, 6915, 6916, 6920, 6923, 6924, 6925, 6926, 6927, 6929, 6932, 6937, 6938, 6941, 6947, 6951, 6952, 6954, 6958, 6961, 6962, 6963, 6965, 6966, 6967, 6971, 6973, 6976, 6981, 6985, 6986, 6988, 6989, 6995, 6996, 6997, 6999, 7003, 7004, 7011, 7012, 7013, 7014, 7022, 7102, 7105, 7122, 7148, 7150, 7161, 7164, 7167, 7173, 7180, 7181, 7182, 7184, 7186, 7189, 7190, 7191, 7198, 7201, 7202, 7203, 7205, 7211, 7212, 7213, 7214, 7215, 7220, 7222, 7224, 7226, 7230, 7231, 7236, 7238, 7239, 7240, 7241, 7242, 7244, 7245, 7246, 7247, 7250, 7251, 7256, 7259, 7260, 7261, 7266, 7267, 7269, 7270, 7271, 7272, 7274, 7276, 7277, 7278, 7280, 7282, 7283, 7284, 7291, 7294, 7296, 7305, 7309, 7313, 7408, 7414, 7416, 7419, 7420, 7421, 7427, 7433, 7438, 7442, 7445, 7447, 7448, 7451, 7453, 7455, 7456, 7458, 7459, 7463, 7466, 7467, 7475, 7476, 7480, 7481, 7482, 7483, 7487, 7494, 7504, 7506, 7508, 7510, 7512, 7513, 7514, 7516, 7517, 7518, 7520, 7522, 7524, 7525, 7527, 7532, 7537, 7545, 7550, 7552, 7554, 7561, 7570, 7575, 7581, 7591, 7593, 7594, 7595, 7596, 7599, 7600, 7601, 7605, 7606, 7607, 7608, 7609, 7611, 7613, 7615, 7616, 7618, 7619, 7628, 7630, 7637, 7640, 7646, 7649, 7701, 7702, 7709, 7715, 7717, 7718, 7721, 7723, 7725, 7727, 7729, 7730, 7731, 7732, 7733, 7734, 7735, 7739, 7740, 7741, 7743, 7744, 7745, 7751, 7752, 7762, 7769, 7775, 7780, 7782, 7811, 7816, 7817, 7818, 7819, 7820, 7821, 7822, 7823, 7832, 7833, 7838, 7839, 7840, 7844, 7846, 7856, 7860, 7862, 7864, 7867, 7868, 7872, 7873, 7874, 7885, 7893, 7897, 7898, 7905, 7908, 7911, 7912, 7913, 7914, 7915, 7916, 7917, 7918, 7921, 7925, 7936, 7937, 7942, 7943, 7947, 7949, 7951, 7952, 7955, 7956, 7958, 7961, 7962, 7966, 7970, 7971, 7972, 7974, 7976, 7979, 7981, 7984, 7987, 7988, 7989, 7990, 7994, 7995, 7999, 8001, 8002, 8005, 8007, 8008, 8011, 8012, 8013, 8014, 8015, 8016, 8018, 8020, 8022, 8025, 8028, 8029, 8031, 8032, 8035, 8036, 8037, 8038, 8041, 8043, 8050, 8051, 8052, 8053, 8056, 8057, 8058, 8059, 8060, 8061, 8065, 8068, 8070, 8074, 8075, 8077, 8078, 8079, 8081, 8084, 8086, 8087, 8088, 8089, 8090, 8091, 8093, 8095, 8096, 8097, 8098, 8101, 8103, 8107, 8111, 8113, 8114, 8118, 8125, 8127, 8129, 8130, 8131, 8132, 8133, 8136, 8137, 8140, 8141, 8142, 8150, 8151, 8153, 8154, 8155, 8158, 8159, 8160, 8163, 8165, 8166, 8168, 8173, 8174, 8179, 8181, 8182, 8184, 8185, 8194, 8200, 8201, 8203, 8207, 8214, 8217, 8218, 8219, 8227, 8230, 8233, 8237, 8242, 8244, 8251, 8252, 8253, 8255, 8260, 8267, 8273, 8274, 8275, 8276, 8278, 8279, 8281, 8282, 8283, 8285, 8289, 8291, 8303, 8304, 8306, 8308, 8309, 8316, 8324, 8325, 8331, 8334, 8336, 8337, 8338, 8341, 8342, 8343, 8344, 8345, 8346, 8349, 8350, 8354, 8355, 8356, 8358, 8359, 8360, 8361, 8362, 8363, 8364, 8365, 8366, 8367, 8368, 8369, 8370, 8374, 8377, 8379, 8381, 8382, 8383, 8385, 8386, 8387, 8388, 8392, 8393, 8395, 8396, 8397, 8399, 8410, 8411, 8416, 8418, 8423, 8424, 8425, 8439, 8473, 8511, 8515, 8518, 8519, 8521, 8522, 8524, 8527, 8529, 8530, 8537, 8541, 8542, 8543, 8544, 8545, 8550, 8551, 8558, 8562, 8563, 8566, 8570, 8572, 8584, 8585, 8586, 8589, 8591, 8593, 8595, 8596, 8600, 8601, 8604, 8609, 8613, 8614, 8616, 8617, 8622, 8624, 8628, 8630, 8692, 8697, 8698, 8703, 8706, 8707, 8708, 8713, 8714, 8715, 8725, 8729, 8732, 8742, 8750, 8766, 8769, 8771, 8772, 8793, 8795, 8798, 8801, 8802, 8803, 8804, 8806, 8818, 8830, 8835, 8840, 8841, 8842, 8848, 8850, 8860, 8864, 8869, 8871, 8876, 8877, 8881, 8892, 8897, 8904, 8905, 8917, 8918, 8919, 8920, 8923, 8928, 8933, 8934, 8935, 8940, 8944, 8999, 9001, 9003, 9005, 9006, 9007, 9008, 9009, 9010, 9014, 9020, 9021, 9022, 9024, 9025, 9031, 9037, 9039, 9041, 9042, 9044, 9045, 9046, 9048, 9052, 9058, 9062, 9064, 9065, 9066, 9067, 9068, 9069, 9070, 9072, 9074, 9075, 9076, 9081, 9086, 9090, 9099, 9101, 9104, 9107, 9110, 9115, 9119, 9130, 9142, 9143, 9201, 9202, 9232, 9260, 9265, 9267, 9301, 9302, 9303, 9304, 9305, 9306, 9308, 9310, 9312, 9319, 9322, 9324, 9351, 9358, 9364, 9366, 9368, 9369, 9370, 9375, 9380, 9381, 9384, 9386, 9401, 9404, 9405, 9409, 9412, 9413, 9414, 9416, 9418, 9419, 9422, 9424, 9428, 9432, 9433, 9435, 9437, 9438, 9449, 9466, 9468, 9470, 9474, 9475, 9479, 9501, 9502, 9503, 9504, 9505, 9506, 9507, 9508, 9509, 9511, 9513, 9514, 9517, 9531, 9532, 9533, 9534, 9535, 9536, 9543, 9551, 9600, 9601, 9602, 9603, 9605, 9612, 9613, 9616, 9619, 9621, 9622, 9624, 9627, 9628, 9629, 9632, 9633, 9644, 9658, 9663, 9671, 9672, 9675, 9678, 9681, 9682, 9684, 9692, 9697, 9699, 9702, 9704, 9706, 9715, 9716, 9717, 9719, 9722, 9726, 9728, 9729, 9731, 9735, 9739, 9740, 9742, 9743, 9744, 9746, 9747, 9749, 9755, 9757, 9759, 9760, 9763, 9765, 9766, 9768, 9769, 9783, 9787, 9788, 9790, 9792, 9793, 9795, 9810, 9824, 9828, 9830, 9831, 9832, 9837, 9842, 9843, 9850, 9854, 9856, 9861, 9869, 9880, 9882, 9887, 9889, 9896, 9900, 9902, 9919, 9928, 9930, 9932, 9934, 9936, 9945, 9946, 9948, 9956, 9957, 9960, 9962, 9966, 9972, 9974, 9979, 9982, 9983, 9984, 9986, 9987, 9989, 9990, 9991, 9993, 9994, 9995, 9997] 

def downloadWebPng(url, pre):
  request = urllib2.Request(url)
  img = urllib2.urlopen(request).read()
  parts = url.split("/")
  with open (pre + parts[-1], 'w') as f: f.write(img)
  f.close()
  time.sleep(1)
  with open (LAT_DIR + parts[-1], 'w') as f: f.write(img)
  f.close()

def hcCode():
  url = "http://127.0.0.1/ifis/ifis.php"
  resp = urllib2.urlopen(url)
  return "&hc=" + resp.read()

# https://monex.ifis.co.jp/index.php?action=tp2&sa=screenRankDetail&ta=c&scid=7&hc=c5d96ddee0f49dfbe7f74e0a5cebcd6482fdf892
def ifisUrl(page_id, hc_code):
  arg0 = "index.php?"
  arg1 = "action=tp2&sa=screenRankDetail&"
  arg2 = "ta=c&scid=7&"
  arg3 = "pageID=" + str(page_id)
  return BASE_URL + arg0 + arg1 + arg2 + arg3 + hc_code


# "%Y%m%d%H%M%S"
now = datetime.datetime.now()

try:
  hc_code = hcCode()

  list = []
  stock = {}

  n = 1
  while True:
    url = ifisUrl(n, hc_code)  # pageID=<n>
    resp = urllib2.urlopen(url)

    # parse html
    soup = BeautifulSoup(resp, "html.parser")

    # left and right column
    l_boxes = soup.select('.c_group')
    for box in l_boxes:
      # print(box)
      stock['name'] = box.find("a", class_="stock_name").text.encode('utf-8')
      stock['code'] = int(re.sub('[()]', '',
        box.find("span", class_="code").text))

      tdLst = []
      for td in box.find("table").find_all("td"):
        tdTxt = td.text
        spanTxt = td.find("span", class_="scale").text

        # remove scale from "td" text
        numTxt = tdTxt.replace(spanTxt, '')

        # print(numTxt)
        tdLst.append(numTxt.strip())
        # print(spanTxt)
        tdLst.append(spanTxt.strip())

      # to set stock object
      stock['price'] = float(re.sub('[,]', '', tdLst[0]))
      # stock['yen'] = tdLst[1]
      stock['ratingNow'] = float(tdLst[2])
      stock['ratingChg'] = float(re.sub('[()]', '', tdLst[3]))

      tdLst[4] = tdLst[4].replace("--", '0.0')
      stock['compPredict'] = float(re.sub('[,]', '', tdLst[4]))

      tdLst[5] = tdLst[5].replace("(--%)", '0.0')
      stock['compIncRatio'] = float(re.sub('[,%()]', '', tdLst[5]))/100

      tdLst[6] = tdLst[6].replace("--", '0.0')
      stock['consPredict'] = float(re.sub('[,]', '', tdLst[6]))

      tdLst[7] = tdLst[7].replace("(--%)", '0.0')
      stock['consIncRatio'] = float(re.sub('[,%()]', '', tdLst[7]))/100

      list.append(stock)
      stock = {}

      # download stock png image
      pngUrl = BASE_URL + box.find("div", class_="chart").find("a") \
               .find("img")['src']
      # print(pngUrl)
      downloadWebPng(pngUrl, PNG_DIR + now.strftime("%Y%m%d") + "_")

    # right/left column
    '''
    r_boxes = soup.find_all("div", class_="c_group r_box/l_box")
    for box in r_boxes:
      print(box.text)
    '''

    # if none "next page", then break this while loop in the end
    nextLnk = soup.find("a", title="next page")
    if nextLnk is None:
      print("Last pageID is " + str(n))
      break

    print("Current pageID is " + str(n))
    n += 1
    time.sleep(1)

  # write json
  f = open(now.strftime("%Y%m%d") + ".json", "w")
  f.write(json.dumps(list, ensure_ascii=False)) # JPN utf-8
  f.close()

except Exception as e:
    print("error: {0}".format(e), file=sys.stderr)
    exitCode = 2


for s in all_stocks:
  try:
    pngName = str(s) + ".png"
    pngUrl = BASE_URL + "img/graph/chart/" + pngName
    # create a request object
    request = urllib2.Request(pngUrl)

    # and open it to return a handle on the url
    png = urllib2.urlopen(request).read()

    # write img into file
    with open (PNG_DIR + now.strftime("%Y%m%d") + "_" + pngName, 'w') as f: f.write(png)
    time.sleep(1)
    f.close()

  except urllib2.HTTPError, e:
    # print 'We failed with error code - %s.' % e.code

    if e.code == 404:
        print(e.code)
        # do stuff..  
    else:
        print(e.code)
        # other stuff...

    # return False
    print("ng: next")
  else:
    print("ok: next")

