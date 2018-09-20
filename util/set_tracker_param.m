close all;
addpath('caffe/matlab/', 'util');

data_path = [seq.path seq.name '/'];
imgs = dir([data_path 'img/*.jpg']);
im1_id = seq.startFrame;
end_id = seq.endFrame;
sample_res = ['sample_res/' seq.name '/'];
if ~isdir(sample_res)
    mkdir(sample_res);
end
%% init caffe %%
gpu_id = 0;
caffe.set_mode_gpu();
caffe.set_device(gpu_id);
feature_solver_def_file = 'model/feature_solver.prototxt';
model_file = 'model/VGG_ILSVRC_16_layers.caffemodel';
fsolver = caffe.Solver(feature_solver_def_file);
fsolver.net.copy_from(model_file);
%% spn solver
spn_solver_def_file = 'model/spn_solver.prototxt';
spn = caffe.Solver(spn_solver_def_file);
%% cnn-a solver
cnna_solver_def_file = 'model/cnn-a_solver.prototxt'; 
cnna = caffe.Solver(cnna_solver_def_file);
max_iter = 180;
mean_pix = [103.939, 116.779, 123.68]; 
% 
% %% Init location parameters
dia = (seq.init_rect(3)^2+seq.init_rect(4)^2)^0.5;
rec_scale_factor = [dia/seq.init_rect(3), dia/seq.init_rect(4)];
center_off = [0,0];
roi_scale = 2;
roi_scale_factor = roi_scale*[rec_scale_factor(1),rec_scale_factor(2)];
map_sigma_factor = 1/12;
roi_size = 361;
location = seq.init_rect;
% %% init ensemble parameters
ensemble_num = 100;
w0 = single(ones(1, 1, ensemble_num, 1));
wt0 = w0;
wt = single(zeros(1, 1, ensemble_num, 1));
eta = 0.2; % weight of selected feature maps
%% Init scale parameters
scale_param = init_scale_estimator;
%%
