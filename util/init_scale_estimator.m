function[scale_param] = init_scale_estimator
scale_param.scale_thr = 0.05;
scale_param.scale_sigma_factor = 1/4;
scale_param.number_of_scales_test = 9; 
scale_param.number_of_scales_train = 33;
scale_param.scale_step = 1.02;
scale_param.scale_sigma = sqrt(scale_param.number_of_scales_train) * scale_param.scale_sigma_factor;
ss = (1:scale_param.number_of_scales_train) - ceil(scale_param.number_of_scales_train/2);
ys = exp(-0.5 * (ss.^2) / scale_param.scale_sigma^2);
scale_param.y = single(ys);
scale_param.scale_window_train = single(hann(scale_param.number_of_scales_train));
scale_param.scale_window_test = scale_param.scale_window_train((scale_param.number_of_scales_train - scale_param.number_of_scales_test)/2 + 1: (scale_param.number_of_scales_train + scale_param.number_of_scales_test)/2);
ss = 1:scale_param.number_of_scales_train;
scale_param.scaleFactors_train = scale_param.scale_step.^(ceil(scale_param.number_of_scales_train/2) - ss);
ss = 1:scale_param.number_of_scales_test;
scale_param.scaleFactors_test = scale_param.scale_step.^(ceil(scale_param.number_of_scales_test/2) - ss);
end

