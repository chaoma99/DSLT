function [im_patch, padded_im, roi_pos,left_pad, top_pad, right_pad, bottom_pad] =... 
get_subwindow_avg1(im, GT, l_off, r_w_scale)
%function [roi, roi_pos, preim, pad] = ext_roi(im, GT, l_off, roi_size, r_w_scale)
avg_chans = [mean(mean(im(:,:,1))) mean(mean(im(:,:,2))) mean(mean(im(:,:,3)))];
[h, w, ~] = size(im);
win_w = GT(3);
win_h = GT(4);
win_lt_x = GT(1);
win_lt_y = GT(2);
win_cx = round(win_lt_x+win_w/2+l_off(1));
win_cy = round(win_lt_y+win_h/2+l_off(2));
roi_w = r_w_scale(1)*win_w;
roi_h = r_w_scale(2)*win_h;
x1 = win_cx-round(roi_w/2);
y1 = win_cy-round(roi_h/2);
x2 = win_cx+round(roi_w/2);
y2 = win_cy+round(roi_h/2);
left_pad=0;
top_pad=0;
right_pad=0;
bottom_pad=0;
im = double(im);
if x1<=0
    pad = abs(x1)+1;
    left_pad = pad;
    R = padarray(im(:,:,1), [0 pad], avg_chans(1), 'pre');
    G = padarray(im(:,:,2), [0 pad], avg_chans(2), 'pre');
    B = padarray(im(:,:,3), [0 pad], avg_chans(3), 'pre');
    im = cat(3, R, G, B);
    x1 = x1+pad;
end
if y1<=0
    pad = abs(y1)+1;
    top_pad=pad;
    R = padarray(im(:,:,1), [pad 0], avg_chans(1), 'pre');
    G = padarray(im(:,:,2), [pad 0], avg_chans(2), 'pre');
    B = padarray(im(:,:,3), [pad 0], avg_chans(3), 'pre');
    im = cat(3, R, G, B);
    y1 = y1+pad;
end
if (h-y2)<=0
    pad = abs(h-y2)+1;
    bottom_pad=pad;
    R = padarray(im(:,:,1), [pad 0], avg_chans(1), 'post');
    G = padarray(im(:,:,2), [pad 0], avg_chans(2), 'post');
    B = padarray(im(:,:,3), [pad 0], avg_chans(3), 'post');
    im = cat(3, R, G, B);
    %y2 = y2+pad;
end
if (w-x2)<=0
    pad = abs(w-x2)+1;
    right_pad = pad;
    R = padarray(im(:,:,1), [0 pad], avg_chans(1), 'post');
    G = padarray(im(:,:,2), [0 pad], avg_chans(2), 'post');
    B = padarray(im(:,:,3), [0 pad], avg_chans(3), 'post');
    im = cat(3, R, G, B);
    %x2 = x2+pad;
end
im_patch  = im(y1:y2, x1:x2, :);
padded_im = zeros(size(im,1), size(im,2));
roi_pos = [x1, y1, x2-x1+1, y2-y1+1];
% marginl = floor((roi_warp_size-roi_size)/2);
% marginr = roi_warp_size-roi_size-marginl;

% roi = roi(marginl+1:end-marginr, marginl+1:end-marginr, :);
% roi = imresize(roi, [roi_size, roi_size]);
end