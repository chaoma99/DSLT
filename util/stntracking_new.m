function [positions, rect_position] = stntracking_new(seq,net,img_files, pos, target_sz, video_path,show_visualization,gt)
%% set maycaffe

%% set tracking interface

bbr = 0; %bounding box regression 
detection =0;
CNN = 0;
thresh1 = 0.2; %for hog feature=0.2 
%addpath(genpath('/home/luxiankai/code/CFRP/'));
video = seq.name;
%[img_files, pos, target_sz, ground_truth, video_path] = load_video_info(base_path, video);

im = imread([video_path img_files{1}]); 
if size(im,3)<2
    im = cat(3,im,im,im);
end
set_tracker_parameter;
%show_visualization = 0;
if show_visualization,  %create video interface
   update_visualization = show_video(img_files, video_path, 0);
end
%% setting of correlation filter
if CNN 
    app_yf=fft2(gaussian_shaped_labels(output_sigma, [6 6]));
else
    app_yf=fft2(gaussian_shaped_labels(output_sigma, floor(app_sz / cell_size)));
end
cos_window1 = ones(size(app_yf,1),size(app_yf,2));
config.cos_window = cos_window1;
app_xf=0;
app_alphaf=0;
%% bounding box regression
 opts = mdnet_init(im,imageSz); 
if bbr
   gt1 = [pos([2,1]) target_sz([2,1])];
   targetLoc = [gt(1,1:2)-gt(1,3:4)./2 gt(1,[3,4])]; %top left w h   
   pos_examples = gen_samples('uniform_aspect', targetLoc, opts.bbreg_nSamples*10, opts, 0.3, 10);
   r = overlap_ratio(pos_examples,targetLoc);
   pos_examples = pos_examples(r>0.6,:);
   pos_examples = pos_examples(randsample(end,min(opts.bbreg_nSamples,end)),:);
   feat_conv = mdnet_features_convX(net, im, pos_examples, opts);
 %  X = X(:,:); %num* feature_dim 
   feat_conv = permute(feat_conv,[4,3,1,2]);
   X= feat_conv(:,:);   
   bbox = pos_examples; %num*4
   bbox_gt = repmat(targetLoc,size(pos_examples,1),1); %num*4
   bbox_reg = train_bbox_regressor(X, bbox, bbox_gt);
end

im_pool = [];
im_res = [];
[rat1,rat2]= deal(win_sz(1)./target_sz(1),win_sz(2)./target_sz(2));
%%
positions = zeros(numel(img_files),4);
rect_position = zeros(numel(img_files),4);
tic;
ind = 1;
for frame = 1:numel(img_files),
    im = imread([video_path img_files{frame}]);
    
    if size(im,3)<2
        im = cat(3,im,im,im);
    end
    top_left = pos([2,1])-win_sz([2,1])./2;
   if frame>1
    win_sz = target_sz.*[rat1 rat2];
    [img,pad] = get_subwindow(single(im),pos,floor(win_sz));     
    img1 = imresize(img,[base_win_sz(1) base_win_sz(2)],'bilinear');
    input_img = impreprocess(img1); 
    net.blobs('img').set_data(input_img);
    sum_delta_p = [];
    res_all = [];
    if mod(frame,5)==1
    for ii = 1:length(im_res)
        img_p = im_pool(:,:,:,ii);
        net.blobs('gt_p').set_data(img_p);
        net.forward_prefilled();
        crop = net.blobs('st_output').get_data();
        theta = net.blobs('theta').get_data();
        theta = [theta(1) 0 theta(2) 0 theta(3) theta(4)];
        nfeat_p = net.blobs('nfeat_p').get_data();
        nfeat = net.blobs('nfeat').get_data();
        sub_response = nfeat'*nfeat_p;
        res_all = [res_all sub_response];
        %im_pool{ii,2} = response;
    
%     if show_visualization,
%         fprintf('Frame: %d response: %f \n', frame, response);
%     end
    
    %figure(3),imshow(mat2gray(img1));
        out_axis1 = [theta(1:3);theta(4:6)]*[1 1 1]';%[   0.5840    0.3054];
        out_axis2 = [theta(1:3);theta(4:6)]*[-1 -1 1]';%%[   -0.3846   -0.7270];
        out_axis1 =  (out_axis1+1)./2;
        out_axis2 =  (out_axis2+1)./2;
        %hold on,rectangle('position',[227*(out_axis2([2,1])) 227*(out_axis1([2,1]))-227*(out_axis2([2,1]))],'edgecolor','g');
        %figure(4),imshow(mat2gray(img));
        box_corner = imageSz*(out_axis2([2,1]))./[ratio2; ratio1];
        box_sz = ((imageSz*(out_axis1([2,1]))-imageSz*(out_axis2([2,1])))./[ratio2 ;ratio1]);
        %hold on,rectangle('position',[box_corner box_sz],'edgecolor','g');
        box_loc= top_left+box_corner';
        delta_p =  ((out_axis1([2,1])+out_axis2([2,1]))*imageSz./2)' - base_win_sz./2;
        delta_p = delta_p ./[ratio2 ratio1];
        %pos1 = pos([2,1]) + delta_p;
        sum_delta_p = [sum_delta_p; delta_p];
    end
        [response,indx] = max(res_all);
        delta_p = sum_delta_p(indx,:);
        pos = pos + delta_p([2,1]);%ground_truth(frame,[2,1]);

%     pos = box_loc([2,1])+(box_sz([2,1])./2)';
   end
   
    img_p = get_subwindow(im,pos,target_sz);    
    img_p = imresize(single(img_p),[base_win_sz(1) base_win_sz(2)],'bilinear');
    if size(img_p,3)<2
        img_p = cat(3,img_p,img_p,img_p);
    end
    img_p = impreprocess(single(img_p));
    if frame>1&&response>0.5||frame==2
        ind = ind+1;
        if ind<6
        im_pool = cat(4,im_pool, img_p);
        im_res = [im_res response];
        else
            im_pool(:,:,:,mod(ind,5)+1) = img_p;
            im_res(mod(ind,5)+1) = response;
            ind = 1;
        end
    end
    %% bounding box regression
    if frame>1&&bbr&&response>0.56   %% bounding box regression  
        X_= net.blobs('conv4').get_data(); %num*dim
        X_ = X_(:,:,:,1);
        X = permute(X_,[3,1,2]);
        %X_ = X_';
        X_ = X(:);
        X_ = X_';
        box_sz = box_sz';
        bbox_ = [pos - box_sz([2,1])./2 box_sz([2,1])]; %num*4
        %bbox_ = [pos - target_sz./2 target_sz]; %num*4
        bbox_ = [bbox_([2,1]) bbox_([4,3])];
        pred_boxes = predict_bbox_regressor(bbox_reg.model, X_, bbox_);
        pos = pred_boxes([2,1])+pred_boxes([4,3])./2;
        %target_sz = pred_boxes([4,3]);
    end
    
    if frame==1
        img_p1 = img_p; 
        im_pool = [im_pool img_p1];
        im_res = [im_res 1];
%     elseif bbr
%         target_sz = pred_boxes([4,3]);
%         target_sz = target_sz';
%     else
%         target_sz = box_sz([2,1]);
%         target_sz = target_sz'; 
    end
   
    positions(frame,:) = [pos target_sz];
    rect_position(frame,:) = [pos([2,1]) - floor(target_sz([2,1])/2), target_sz([2,1])];
    if show_visualization,
			box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
%             if frame>1
%                 box = [pos([2,1]) - box_sz'/2, box_sz'];
%             end
			stop = update_visualization(frame, box);
			if stop, break, end  %user pressed Esc, stop early
			
			drawnow
%            figure(5),imshow(mat2gray(im));
%            hold on,rectangle('position',[top_left win_sz([2,1])],'edgecolor','y');
%            hold on,rectangle('position',[gt(frame,[1,2])-gt(frame,[3,4])./2 target_sz([2,1])],'edgecolor','r');
			%pause(0.05)  %uncomment to run slower
   end
    %figure,imshow(mat2gray(permute(img_p,[2,1,3])));

end

t = toc;
fprintf('Speed: %0.3f fps\n', numel(img_files)/t);