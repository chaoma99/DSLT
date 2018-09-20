function scale_sample = get_scale_sample(fea, scaleFactors, tmp_target_sz)
num = length(scaleFactors);
num1 = 31;
scale_window_train = single(hann(num1));
scale_window = scale_window_train((num1 - num)/2 + 1: (num1 + num)/2);
fea_sz = size(fea);
scale_sample = single(zeros(fea_sz(1), fea_sz(2), fea_sz(3), num));
for scale_id = 1:length(scaleFactors)
    re_sz = 2 * floor(fea_sz(1:2) / 2 * scaleFactors(scale_id));
   fea_resized = imresize(fea, re_sz); 
   xs_start = max((re_sz(2) - fea_sz(2))/2, 0) + 1;
   ys_start = max((re_sz(1) - fea_sz(1))/2, 0) + 1;
   xs_end = re_sz(2) - xs_start + 1;
   ys_end = re_sz(1) - ys_start + 1;
   
   xt_start = max((fea_sz(2) - re_sz(2))/2, 0) + 1;
   yt_start = max((fea_sz(1) - re_sz(1))/2, 0) + 1;
   xt_end = fea_sz(2) - xt_start + 1;
   yt_end = fea_sz(1) - yt_start + 1;
   
   scale_sample(yt_start:yt_end, xt_start:xt_end ,:, scale_id) = fea_resized(ys_start:ys_end, xs_start:xs_end, :)* scale_window(scale_id) ;
end