function results = DSLT(seq, visualization)
cleanupObj = onCleanup(@cleanupFun);
rand('state', 0);
%dbstop if error;
focal = 0;
warning off;
%visualization = false;
im1 = double(imread([seq.path seq.img_files{1}]));
addpath(genpath('util'));
addpath('./caffe-dslt/matlab/'); %caffe path
addpath(genpath('toolbox'));
caffe.set_mode_gpu();
gpu_id = 0;  % we will use the first gpu in this demo
caffe.set_device(gpu_id);
net_weights =fullfile('model/new_vgg_net.caffemodel');  % revised VGG model
prototxt = 'prototxt/';

min_roi_size= [200 200];
%red_dim= 64; %256
num = 7;% past 5 samples are used for updating network
thr1 = 0.0;%0.3
fea_cell = cell(num,1);
map_cell = cell(num,1);
im1 = im1;
iterations = 0;

if size(im1,3)~=3
    im1(:,:,2) = im1(:,:,1);
    im1(:,:,3) = im1(:,:,1);
end
scale=1;
max_size = 80;
bb1 = seq.init_rect;%  %[262,98,72,84];%
if bb1(3)*bb1(4)>max_size*max_size||bb1(3)>2*max_size||bb1(4)>2*max_size
    scale = max_size/max(bb1([3,4]));
end
bb1 = bb1*scale;
im1 = imresize(im1,scale);
context = [ 9-1, 5-1];
context = (scale*context);
location = bb1;
target_sz = bb1([4,3]);

patch = get_crops(im1, bb1, context);
patch_aug = my_data_augmentation(patch);
rec_scale_factor = context+1;
center_off = [0,0];
roi_scale_factor = [rec_scale_factor(1),rec_scale_factor(2)];
if size(patch,1)*size(patch,2)<min_roi_size(1)*min_roi_size(2)
    ratio = sqrt(min_roi_size(1)*min_roi_size(2)/(size(patch,1)*size(patch,2)));
else
    ratio = 1;
end
warning off ;
patch = impreprocess1(patch,ratio);
roi_size = size(patch);
revise_prototxt1([prototxt 'otb'], 'prototxt/fea_net1.prototxt', roi_size([2,1])); %DenseNet_121_new.prototxt
net_model = [prototxt 'otb' '_fea_net.prototxt'];
phase = 'test';
net = caffe.Net(net_model, net_weights,phase);
layer_name1 = 'conv4_3';%
layer_name2 = 'conv5_3';
net.blobs('data').set_data(patch);
net.forward_prefilled();
fea_map = net.blobs(layer_name1).get_data(); %59*77*51 162*105
fea_map2 = net.blobs(layer_name2).get_data();
fea_sz = size(fea_map);

im2_id=0;
tmp_target_sz = floor(target_sz.*ratio.*(fea_sz([2,1])./([size(patch,2) size(patch,1)])));
if bb1([3])*bb1([4])>100*100 && bb1([3])*bb1([4])<150*150
   tmp_target_sz = floor(0.7*tmp_target_sz);
elseif bb1([3])*bb1([4])>=150*150 && bb1([3])*bb1([4])<250*250
    tmp_target_sz = floor(0.4*tmp_target_sz);
end
revise_se_res_layer('otb','prototxt/vgg_se_res_layer.prototxt', fea_sz([2,1]), tmp_target_sz);
revise_se_res_layer_test('otb','prototxt/vgg_se_res_layer_test.prototxt', fea_sz([2,1]), tmp_target_sz);
adjust_solver_def_file = ['prototxt/vgg_se_res_solver.prototxt'];
adjust_solver_def_file1 = ['prototxt/vgg_se_res_solver1.prototxt'];
%solver_revise(adjust_solver_def_file);
adjust_solver = caffe.Solver(adjust_solver_def_file);
adjust_solver1 = caffe.Solver(adjust_solver_def_file1);

sigma1 = 0.08*tmp_target_sz; %*1.5
sigma2 = 0.65*tmp_target_sz;
%
res_map = adjust_solver.net.forward({fea_map,fea_map2}); 
res_sz = size(res_map{1});
regression_map =  GetMap(size(im1), fea_sz, res_sz, roi_size, floor(location), center_off,...
  roi_scale_factor, sigma1, 'trans_gaussian');
motion_map =  GetMap(size(im1), fea_sz, res_sz, roi_size, floor(location), center_off,...
  roi_scale_factor, sigma2, 'trans_gaussian');
count=1;
fea_cell{1,1} = fea_map;
fea_cell{1,2} = fea_map2;
map_cell{1,1} = regression_map;
adjust_solver.net.set_net_phase('train');
%% ===========================scale estimation part=====================================
currentScaleFactor = [1.0];
base_target_sz = target_sz / currentScaleFactor;
nScales= 3;
scale_step = 1.03;
sz = repmat(sqrt(prod(base_target_sz)),1,2);
if nScales > 0
    scale_exp = (-floor((nScales-1)/2):ceil((nScales-1)/2));    
    scaleFactors = scale_step .^ scale_exp;
    w_h_ratio = bb1([3])/bb1([4]);
    max_w_h_ratio = max(2*w_h_ratio, 2/w_h_ratio);
    min_w_h_ratio = 1/(max_w_h_ratio);
    %force reasonable scale changes
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im1,1) size(im1,2)] ./ base_target_sz)) / log(scale_step));
end
response_map = zeros(size(res_map{1},1),size(res_map{1},2),nScales);
%% Iterations
aug_len = length(patch_aug);
last_loss = 1e3;
for i = 1:100
    indx = randi(aug_len);
     patch = patch_aug{indx,1};
     patch = impreprocess1(patch,ratio);
    net.blobs('data').set_data(patch);
    net.forward_prefilled();
    fea_map = net.blobs(layer_name1).get_data(); %59*77*51 162*105
    fea_map2 = net.blobs(layer_name2).get_data();    
    res_map = adjust_solver.net.forward({fea_map,fea_map2});
    if visualization
       figure(10011); subplot(1,2,1); imagesc(permute(res_map{1,1},[2,1,3]));%imagesc([1,size(patch,1)],[1, size(patch,2)],permute(res_map{1,1},[2,1,3]));%
    end
    if focal,
        [loss, delta_logistic] =  loss_object_grad_focal(res_map{1,1},regression_map); %focal loss %
    else
        [loss, delta_logistic] =  loss_object_grad(res_map{1,1},regression_map); %shrinkage loss
    end
        %assert(cdl==1);
    adjust_solver.net.backward({delta_logistic});
    adjust_solver.apply_update();
    %loss_train = loss_train + loss;
    if visualization
       figure(10011); subplot(1,2,2); imagesc(permute(regression_map,[2,1,3]));
       pause(0.01);
       fprintf('Iter %d: training error is %f \n', i, sum(abs(loss(:))));
    end
    if sum(abs(loss(:))) < 0.03 %|| last_loss < sum(abs(loss(:)))
        break;
    end  
    last_loss = sum(abs(loss(:)));
end
%% ================================================================
adjust_solver.net.save('model/finetune_net.caffemodel');
adjust_solver.net.set_net_phase('test');
adjust_solver1.net.copy_from('model/finetune_net.caffemodel');
positions = [];
tic;
for im2_id = 1:numel(seq.img_files)
    adjust_solver1.net.set_net_phase('test');
    if visualization
    fprintf('Processing Img: %d/%d\t', im2_id, numel(seq.img_files));
    end
    im2 = double(imread([seq.path seq.img_files{im2_id}]));
    if size(im2,3)~=3
        im2(:,:,2) = im2(:,:,1);
        im2(:,:,3) = im2(:,:,1);
    end 
    %% extract roi and display
    im2 = imresize(im2,scale);
    [roi, padded_zero_map, roi_pos, left_pad_z, top_pad_z, right_pad_z, bottom_pad_z] =...
       get_crops(im2, location, context);
    motion_map =  GetMap(size(im2), fea_sz, res_sz, roi_size, (location), center_off,...
    roi_scale_factor, sigma2, 'trans_gaussian');
    %figure,imshow(mat2gray(motion_map))
    roi = imresize(roi, roi_size([2,1]), 'bilinear');
    roi2 = impreprocess(roi);
    net.blobs('data').set_data(roi2);
    net.forward_prefilled();
    fea_map1 = net.blobs(layer_name1).get_data(); %59*77*51 162*105
    fea_map2 = net.blobs(layer_name2).get_data(); %59*77*51 162*105
   
%% compute confidence map
    pre_heat_map = adjust_solver1.net.forward({fea_map1,fea_map2});
    %new_pre_heat_map  = pre_heat_map{1,1}.*(motion_map);
    %% compute local confidence
    new_pre_heat_map= imresize(pre_heat_map{1,1}', roi_pos(4:-1:3),'bicubic'); %,
    pre_heat_map_up = imresize(motion_map', roi_pos(4:-1:3),'bicubic').*new_pre_heat_map;
    pre_img_map = padded_zero_map; %padded image size
    pre_img_map(roi_pos(2):roi_pos(2)+roi_pos(4)-1, roi_pos(1):roi_pos(1)+roi_pos(3)-1) = pre_heat_map_up;
    pre_img_map = pre_img_map(top_pad_z+1:end-bottom_pad_z, left_pad_z+1:end-right_pad_z);   
    [center_y, center_x] = find(pre_img_map == max(pre_img_map(:))); %location in origin image 
    center_x = mean(center_x);
    center_y = mean(center_y);
    base_location = [center_x - target_sz(2)/2, center_y - target_sz(1)/2, target_sz([2,1])]; %top left
    %% local scale estimation
    if visualization
     max(pre_heat_map{1}(:))
    end
    if max(pre_heat_map{1}(:))>0.35 && im2_id>1 %scale estimation
        %scale estimation
        sc_roi = get_scale_im(im2, base_location, roi_size([2,1,3]), scaleFactors, context);
        for k=1:nScales
            %for l = 1:nScales
                roi2 = sc_roi(:,:,:,k);
                roi2 = impreprocess(roi2);
                net.blobs('data').set_data(roi2);
                net.forward_prefilled();
                fea_map = net.blobs(layer_name1).get_data(); %59*77*51 162*105
                fea_map2 = net.blobs(layer_name2).get_data(); %59*77*51 162*105                
                %% compute confidence map
                pre_heat_map = adjust_solver1.net.forward({fea_map,fea_map2});            
                response_map(:,:,k) = pre_heat_map{1};%.*scale_window(k);
            %end
        end
        [center_y, center_x, sind_w] = ind2sub(size(response_map),find(response_map == max(response_map(:)),1)); 
        %Ind1 = floor((sind-1)/nScales)+1;
        currentScaleFactor = currentScaleFactor.*scaleFactors(nScales+1-sind_w);%  scaleFactors(nScales +1 -sind_h)]; %
        currentScaleFactor(currentScaleFactor < min_scale_factor) = min_scale_factor;
        currentScaleFactor(currentScaleFactor > max_scale_factor) = max_scale_factor;
    
        target_sz = target_sz*0.4 + 0.6*base_target_sz*currentScaleFactor;
        if target_sz(2)/target_sz(1)> max_w_h_ratio
            target_sz([2]) = target_sz(1)*max_w_h_ratio;
        elseif target_sz([2])/target_sz(1)< min_w_h_ratio
            target_sz(2) = target_sz(1)*min_w_h_ratio;
        end
        location = [base_location([1,2]) target_sz([2,1])]; %without scale estimation
    elseif im2_id==1
        location = location;
    else
        sind =  (nScales + 1)./2;
        currentScaleFactor = currentScaleFactor;
        target_sz = target_sz;
        location = [base_location([1,2]) target_sz([2,1])]; %top left
    end
     
    %% update with different strategies for different feature maps

       update = true;
    
    if  update&&im2_id>1 
        %roi2 = ext_roi(im2, location, center_off,  roi_size, roi_scale_factor); %extract sample for based on current position updating
        [roi2] = get_crops(im2, location, context);        
        roi2 = imresize(roi2, [roi_size(2) roi_size(1)], 'bilinear');
        roi2 = impreprocess(roi2);        
        net.blobs('data').set_data(roi2);
        net.forward_prefilled();
        fea_map = net.blobs(layer_name1).get_data(); %59*77*51 162*105
        fea_map2 = net.blobs(layer_name2).get_data(); 
        map2 =  GetMap(size(im2), fea_sz, res_sz, roi_size, floor(location), center_off,...
  roi_scale_factor, sigma1, 'trans_gaussian');
       if max(pre_heat_map{1}(:))> 0.0
           count = count+1;
           if count<num+1
               fea_cell{count,1} = fea_map;   
               fea_cell{count,2} = fea_map2;   
               map_cell{count,1} = map2;
            else
               fea_cell{mod(count,num-1),1} = fea_map;  
               fea_cell{mod(count,num-1),2} = fea_map2;   
               map_cell{mod(count,num-1),1} = map2;
               count = 2;
           end
       end
    %% compute confidence map
    %deep_feature2 = bsxfun(@times, deep_feature2, cos_win);
        adjust_solver1.net.set_net_phase('train');
        for ind = 1:length(fea_cell) %for past 5 samplength
            newfea_map1 = fea_cell{ind,1};   
            newfea_map2 = fea_cell{ind,2};  
            map2 = map_cell{ind,1};
            if ~isempty(newfea_map1)
            %solver_revise(adjust_solver_def_file,lr2);
            for ii = 1:2
                %cnna.net.empty_net_param_diff();                
                pre_heat_map = adjust_solver1.net.forward({newfea_map1,newfea_map2});
                if focal
                    [loss, delta_logistic] =  loss_object_grad_focal(pre_heat_map{1,1}, map2); %loss %
                else
                    [loss, delta_logistic] =  loss_object_grad(pre_heat_map{1,1}, map2); %loss %
                end
                %% first frame
                adjust_solver1.net.backward({delta_logistic*(1)});
                adjust_solver1.apply_update();
            end
            end
        end
        adjust_solver1.net.set_net_phase('test');
  
    end
    
    positions = [positions; location/scale];
    % Drwa resutls
    if visualization
        if im2_id == 1,  %first frame, create GUI
            figure('Name','Tracking Results');
            im_handle = imshow(uint8(im2), 'Border','tight', 'InitialMag', 60 + 60 * (length(im2) < 300));
            rect_handle = rectangle('Position', location, 'EdgeColor','r', 'linewidth', 2);
            text_handle = text(10, 10, sprintf('#%d ',im2_id));
            set(text_handle, 'color', [1 1 0], 'fontsize', 16, 'fontweight', 'bold');
        else
            set(im_handle, 'CData', uint8(im2))
            set(rect_handle, 'Position', location)
            set(text_handle, 'string', sprintf('#%d',im2_id));
        end
        drawnow
    fprintf('\n');
    end
end
t = toc;
results.type = 'rect';
results.res = positions;
%  save([track_res  lower(set_name) '_fct_scale_base1.mat'], 'results');
fprintf('Speed: %0.3f fps\n', numel(seq.img_files)/t);
caffe.reset_all();
end
