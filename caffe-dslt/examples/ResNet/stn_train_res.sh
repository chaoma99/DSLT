#!/usr/bin/env sh

./build/tools/caffe train -solver examples/ResNet/stn_solver_res.prototxt -weights models/ResNet/ResNet-50-model.caffemodel -gpu 0
