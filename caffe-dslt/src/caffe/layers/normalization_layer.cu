// add by Binbin Xu
// declanxu@gmail.com or declanxu@126.com
// Zhejiang University, State Key Lab of CAD&CG.


#include <algorithm>
#include <cfloat>
#include <vector>

// #include "thrust/device_vector.h"
#include "caffe/util/io.hpp"
#include "caffe/layer.hpp"
#include "caffe/util/math_functions.hpp"
#include "caffe/vision_layers.hpp"

namespace caffe {

template <typename Dtype>
void NormalizationLayer<Dtype>::Forward_gpu(const vector<Blob<Dtype>*>& bottom,
    const vector<Blob<Dtype>*>& top) {
  const Dtype* bottom_data = bottom[0]->gpu_data();
  Dtype* top_data = top[0]->mutable_gpu_data();
  Dtype* squared_data = squared_.mutable_gpu_data();
  Dtype normsqr;
  int n = bottom[0]->num();
  int d = bottom[0]->count() / n;
  caffe_gpu_powx(n*d, bottom_data, Dtype(2), squared_data);
  for (int i=0; i<n; ++i) {
    caffe_gpu_asum<Dtype>(d, squared_data+i*d, &normsqr);
    caffe_gpu_scale<Dtype>(d, pow(normsqr, -0.5), bottom_data+i*d, top_data+i*d);
  }
/*
  const Dtype* out = top[0]->cpu_data();
  for (int i=0; i<n; ++i) {
    int ptr = i*d;
    //Dtype tmp = 0.0;
    std::cout << i << ": ";
    for (int j=0; j < d; ++j) {
	//tmp += out[ptr]*out[ptr++];
	std::cout << out[ptr++] << " ";
    }
    std::cout << "\n";
//    LOG(INFO) << i << ": " << tmp;
  }
*/
}
  
template <typename Dtype>
void NormalizationLayer<Dtype>::Backward_gpu(const vector<Blob<Dtype>*>& top,
    const vector<bool>& propagate_down, const vector<Blob<Dtype>*>& bottom) {
  const Dtype* top_diff = top[0]->gpu_diff();
  const Dtype* top_data = top[0]->gpu_data();
  const Dtype* bottom_data = bottom[0]->gpu_data();
  Dtype* bottom_diff = bottom[0]->mutable_gpu_diff();
  int n = top[0]->num();
  int d = top[0]->count() / n;
  Dtype a;
  for (int i=0; i<n; ++i) {
    caffe_gpu_dot(d, top_data+i*d, top_diff+i*d, &a);
    caffe_gpu_scale(d, a, top_data+i*d, bottom_diff+i*d);
    caffe_gpu_sub(d, top_diff+i*d, bottom_diff+i*d, bottom_diff+i*d);
    caffe_gpu_dot(d, bottom_data+i*d, bottom_data+i*d, &a);
    caffe_gpu_scale(d, Dtype(pow(a, -0.5)), bottom_diff+i*d, bottom_diff+i*d);
  }
/*
const Dtype* b = bottom[0]->cpu_data();
for (int i = 0; i < n; i++) {
    std::cout << i << ": ";
    int tmp = i*128;
    for (int j = 0; j < 128; j++) {
	std::cout << b[tmp++] << " ";
    }
    std::cout << "\n:";
}
*/
}

// INSTANTIATE_CLASS(NormalizationLayer);

INSTANTIATE_LAYER_GPU_FUNCS(NormalizationLayer);
}  // namespace caffe
