# -*- coding: utf-8 -*-
"""
Created on Mon Aug  1 22:05:35 2016

@author: luxiankai
"""
import numpy as np
import matplotlib.pyplot as plt
#%matplotlib inline

# Make sure that caffe is on the python path:
caffe_root = '../'  # this file is expected to be in {caffe_root}/examples
import sys
sys.path.insert(0, caffe_root + 'python')

import caffe

plt.rcParams['figure.figsize'] = (10, 10)
plt.rcParams['image.interpolation'] = 'nearest'
plt.rcParams['image.cmap'] = 'gray'

import os
MEAN_FILE=caffe_root+'examples/ResNet/ResNet_mean.binaryproto'
mean_blob = caffe.proto.caffe_pb2.BlobProto()
mean_blob.ParseFromString(open(MEAN_FILE, 'rb').read())

# 将均值blob转为numpy.array
mean_npy = caffe.io.blobproto_to_array(mean_blob)
print mean_npy.shape

