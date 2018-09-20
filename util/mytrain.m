%% new add layer for correlation operation 
warning off;
clear;
dbstop if error;
addpath(genpath('util'));
snapshot = 2000;
scale = 1;
red_dim=64;

  loss_train = 0;
  count = 0;
  iterations = 0;
  context = [9-1,5-1]; %9 for width and 5 for height
  im = imread('/home/machao/luxiankai/otb/Bolt/img/0001.jpg');
  im = double(im);
  bb1 = [336,165,26,61];%  %[262,98,72,84];%
  patch = get_crops(im, bb1, context);
  location = bb1;
  target_sz = bb1([4,3]);
  center_off = [0,0];
  dia = (bb1(3)^2+bb1(4)^2)^0.5;
  rec_scale_factor = context+1;
  center_off = [0,0];
  roi_scale_factor = [rec_scale_factor(1),rec_scale_factor(2)];
  %win_sz = [size(patch,1)- target_sz(1) size(patch,2)- target_sz(2)]; %(context([2,1])+1).*target_sz;
  %label = mygaussian_shaped_labels(sigma1, win_sz);
   %motion_map = mygaussian_shaped_labels(sigma2, win_sz);
  patch = impreprocess(patch);
  count = 1; 
  
  iterations = iterations+1;
%   [a1,a2,a3,a4]=textread('fea_net.prototxt','%s%s%s%s','headerlines',4);
%   a2{3,1} = size(patch,1);
%   a2{4,1} = size(patch,2);
  initialization;
  
  fea_map = fsolver.net.forward({patch}); %59*77*51 162*105
  fea_sz = size(fea_map{1});
  roi_size = size(patch);
  tmp_target_sz = ceil(target_sz./4); %[18 21]%
  sigma1 = 0.1*tmp_target_sz*1.5;
  sigma2 = 0.6*tmp_target_sz;
  fea_map1 = mypca(fea_map{1,1},red_dim);% dimreduction
  res_map = adjust_solver.net.forward({fea_map1}); 
  res_sz = size(res_map{1});
  regression_map =  GetMap(size(im), fea_sz, res_sz, roi_size, location, center_off,...
      roi_scale_factor, sigma1, 'trans_gaussian');
  motion_map =  GetMap(size(im), fea_sz, res_sz, roi_size, location, center_off,...
      roi_scale_factor, sigma2, 'trans_gaussian');
  %motion_map  = mynewGetMap(size(im), [size(res_map{1,1},1) size(res_map{1,1},2)], [size(patch,1) size(patch,2)], location, center_off,  sigma2);
 
for i = 1:4000
    res_map = adjust_solver.net.forward({fea_map1});
    figure(10011); subplot(1,2,1); imagesc(permute(res_map{1,1},[2,1,3]));
    [loss, delta_logistic] =  loss_object_grad(res_map{1,1},regression_map); %loss %
    [wdl,hdl,cdl,bdl] = size(delta_logistic);
        %assert(cdl==1);
    adjust_solver.net.backward({delta_logistic});
    adjust_solver.apply_update();
    %loss_train = loss_train + loss;
    figure(10011); subplot(1,2,2); imagesc(permute(regression_map,[2,1,3]));
    pause(0.01);
    fprintf('Iter %d: training error is %f \n', i, sum(abs(loss(:))));
%     if i>500 && sum(abs(loss(:))) -last_loss<=0
%         break;
%     end
    last_loss = sum(abs(loss(:)));   
end
%  for im2_id = start_frame:end_id
%     adjust_solver.net.set_net_phase('test');
%     fprintf('Processing Img: %d/%d\t', im2_id, end_id);
%     im2_name = sprintf([data_path 'img/%0' num2str(num_z) 'd.jpg'], im2_id);
%     im2 = double(imread(im2_name));
%     if size(im2,3)~=3
%         im2(:,:,2) = im2(:,:,1);
%         im2(:,:,3) = im2(:,:,1);
%     end 