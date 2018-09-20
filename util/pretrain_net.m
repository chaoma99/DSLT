function pretrain_net(im, bb1, opts, fsolver, adjust_solver)
 fsolver.net.set_net_phase('train');
 adjust_solver.net.set_net_phase('train');

 bb1=[bb1(2)-bb1(4)./2 bb1(1)-bb1(3)./2  bb1(4) bb1(3)]; 
 context_amount=opts.context_amount;
 resp_sz = opts.resp_sz;%30-16+1;
 resp_stride = opts.resp_stride;%8; %8->15*15,revised 5
 layer1 = opts.layer1;
 layer2 = opts.layer2;
 aug_opts = opts.augment;
 aug_z = @(crop) acquire_augment(crop, opts.exemplarSize, opts.stats.rgbVariance_z, aug_opts);
 aug_x = @(crop) acquire_augment(crop, opts.instanceSize, opts.stats.rgbVariance_x, aug_opts);
 [derOutputs, instanceWeight, label_inputs_fn] = setup_loss( resp_sz, resp_stride, opts.loss);
 [im_crop_z, bbox_z, pad_z, ~, ~, ~] = get_crops(im, bb1, opts.exemplarSize, opts.instanceSize, context_amount);
 [~, ~, ~, im_crop_x, bbox_x, pad_x] = get_crops(im, bb1, opts.exemplarSize, opts.instanceSize, context_amount);
 iterations=1;
 batch_size=1;
 loss_train=0;
 for i = 1:4000
     count = 1;
     %im_crop_z = aug_z(im_crop_z);
     %imcrop__x = aug_x(im_crop_x);
     [bbox_z, bbox_x] = get_crops1(double(bb1), double(bb1), opts.exemplarSize, opts.instanceSize,context_amount);
    % build related labels and wise labels
     sizes_z(:,count) = bbox_z([4 3]);
     sizes_x(:,count) = bbox_x([4 3]);
     tmp_z = impreprocess(im_crop_z);
     tmp_x = impreprocess(im_crop_x);
     imout_z(:,:,:,count) = tmp_z;
     imout_x(:,:,:,count) = tmp_x;  

     iterations = iterations+1;
 %
    label_inputs = label_inputs_fn(1, sizes_z, sizes_x);
    inputs = [{'exemplar', imout_z, 'instance', imout_x}, label_inputs];           
    resp_map = fsolver.net.forward({imout_z,imout_x});
    out1 = fsolver.net.blobs(layer1).get_data();
    out2 = fsolver.net.blobs(layer2).get_data();
    z = out1; %exemplar
    x = out2; %instance
    assert(size(z,1) <= size(x,1), 'exemplar z has to be smaller than instance x');
    for k = 1:batch_size
        z1 = z(:,:,:,k);
        x1 = x(:,:,:,k);
        [wx,hx,cx,bx] = size(x1);
        x1 = reshape(x1, [wx,hx,cx*bx,1]);
        x1 = 1*10^(0)*x1; %-2
        z1 = 1*10^(0)*z1;
        o = vl_nnconv(x1, z1, []);  %correlation operation z:239*239*96*10  x:127*127*10
        [wo,ho,co,bo] = size(o); % forward
        fac = 1*10^(0);
        temp_o = fac*o; %10^(-3) for convnet 10^6 for deconv 
        score(:,:,k) = (temp_o);%-mean(temp_o(:));
        %score = o;
    end
    ascore = adjust_solver.net.forward({score});
    figure(1011); subplot(1,2,1); imagesc(permute(ascore{1,1},[2,1,3]));
    figure(1011); subplot(1,2,2); imagesc(permute(label_inputs{1,4},[2,1,3])); 
    [loss,delta_logistic] =  loss_logistic_grad(ascore{1,1},label_inputs{1,4},instanceWeight); %loss %
    %[loss, delta_logistic] = loss_crossentropy_paired_softmax_grad(score, label_inputs{1,4}, instanceWeight);
    %dldy = delta_logistic;
    [wdl,hdl,cdl,bdl] = size(delta_logistic);
    %assert(cdl==1);
    adjust_solver.net.backward({delta_logistic});
    dldy = adjust_solver.net.blobs('score').get_diff();
    dldy = reshape(dldy, [wdl,hdl,cdl*bdl,1]);
    dldy = fac*dldy;

    for k = 1:batch_size
        [dldx, dldz, ~] = vl_nnconv(x(:,:,:,k), z(:,:,:,k), [], dldy(:,:,k));
        [mx,nx,cb,one] = size(dldx);
        assert(mx == size(x, 1));
        assert(nx == size(x, 2));
        assert(cb == cx * bx);
        assert(one == 1);
        derInputs1(:,:,:,k) = dldz; %15*15
        derInputs2(:,:,:,k) = dldx;%reshape(dldx, [mx,nx,cx,bx]); %29*29
        fsolver.iteradd();
    end       
    fsolver.net.backward({single(derInputs1),single(derInputs2)} );
    %derInputs1: 15 *15  derInputs2 29*29
    fsolver.apply_update();
    loss_train = loss_train + loss;
    loss_train = loss_train / batch_size;
    fprintf('Iter %d: training error is %f \n', i, loss_train);
    if loss_train<0.1
        break;
    end
    loss_train = 0;


    %count = 0;
    %imout_z = zeros(opts.exemplarSize, opts.exemplarSize, 3, batch_size, 'single');
    %imout_x = zeros(opts.instanceSize, opts.instanceSize, 3, batch_size, 'single');
%  end

%    if mod(iterations,snapshot) == 0
%    weight_name = ['weight' num2str(iterations) '.caffemodel'];
%    fsolver.net.save(weight_name);
%   end
end
  
    %fprintf('Epoches: %d\n', iter);
    weight_name = ['/home/luxiankai/code/mydeconvnet/pretrained_model/weight' '.caffemodel'];
    %adjust_layer_name = ['adjust' num2str(iter) '.caffemodel'];
    fsolver.net.save(weight_name);