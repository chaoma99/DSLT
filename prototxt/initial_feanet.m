function initial_feanet(caffe, )
solver_def_file = 'fea_solver.prototxt'; %de-conv_solver1.prototxt is designed for vgg_deconv
model_file =  '/home/machao/luxiankai/caffe/models/vgg_16layers_fc6/VGG_ILSVRC_16_layers.caffemodel';% 
%'new_vgg_net1.caffemodel';
% %'/home/luxiankai/code/caffe/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
% %new_alex_net
fsolver = caffe.Solver(solver_def_file);
fsolver.net.copy_from(model_file);

