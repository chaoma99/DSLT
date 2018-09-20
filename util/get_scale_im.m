function scale_sample = get_scale_im(im, location, roi_sz, scaleFactors, context)

num = length(scaleFactors);
fea_sz = roi_sz;
scale_sample = single(zeros(fea_sz(1), fea_sz(2), fea_sz(3), num));
for scale_id = 1:length(scaleFactors)
    %location([3,4]) = location([3,4])*scaleFactors(scale_id);
   re_sz = 2 * floor(fea_sz(1:2) / 2 * scaleFactors(scale_id));
   roi1 = get_crops(im, location, context*scaleFactors(scale_id));
   fea_resized = imresize(roi1, re_sz); 
   xs_start = max((re_sz(2) - fea_sz(2))/2, 0) + 1;
   ys_start = max((re_sz(1) - fea_sz(1))/2, 0) + 1;
   xs_end = re_sz(2) - xs_start + 1;
   ys_end = re_sz(1) - ys_start + 1;
   
   xt_start = max((fea_sz(2) - re_sz(2))/2, 0) + 1;
   yt_start = max((fea_sz(1) - re_sz(1))/2, 0) + 1;
   xt_end = fea_sz(2) - xt_start + 1;
   yt_end = fea_sz(1) - yt_start + 1;
   
   scale_sample(yt_start:yt_end, xt_start:xt_end ,:, scale_id) = fea_resized(ys_start:ys_end, xs_start:xs_end, :);
end