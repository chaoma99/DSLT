function [im_patch, padded_im, roi_pos,left_pad, top_pad, right_pad, bottom_pad] = get_subwindow_avg(im, pos, win_sz)
%GET_SUBWINDOW_AVG Obtain image sub-window, padding with avg channel if area goes outside of border
% ---------------------------------------------------------------------------------------------------------------

    avg_chans = [mean(mean(im(:,:,1))) mean(mean(im(:,:,2))) mean(mean(im(:,:,3)))];

   
    sz = win_sz;
    im_sz = size(im);
    %make sure the size is not too small
    assert(all(im_sz(1:2) > 2));
    c = (sz+1) / 2;

    %check out-of-bounds coordinates, and set them to avg_chans
    context_xmin = round(pos(2) - c(2));
    context_xmax = round(pos(2) + c(2));%context_xmin + sz(2)-1;%
    context_ymin = round(pos(1) - c(1));
    context_ymax = round(pos(1) + c(1));%context_ymin + sz(1)-1;%
    left_pad = double(max(0, 1-context_xmin));
    top_pad = double(max(0, 1-context_ymin));
    right_pad = double(max(0, context_xmax - im_sz(2)));
    bottom_pad = double(max(0, context_ymax - im_sz(1)));

    context_xmin = context_xmin + left_pad;
    context_xmax = context_xmax + left_pad;
    context_ymin = context_ymin + top_pad;
    context_ymax = context_ymax + top_pad;

    if top_pad || left_pad
        R = padarray(im(:,:,1), [top_pad left_pad], 'replicate', 'pre');%padarray(im(:,:,1), [top_pad left_pad], avg_chans(1), 'pre');
        G = padarray(im(:,:,2), [top_pad left_pad], 'replicate', 'pre');%padarray(im(:,:,2), [top_pad left_pad], avg_chans(2), 'pre');
        B = padarray(im(:,:,3), [top_pad left_pad], 'replicate', 'pre');%padarray(im(:,:,3), [top_pad left_pad], avg_chans(3), 'pre');
       im = cat(3, R, G, B);
    end

    if bottom_pad || right_pad
        R = padarray(im(:,:,1), [bottom_pad right_pad], 'replicate', 'post');%padarray(im(:,:,1), [bottom_pad right_pad], avg_chans(1), 'post');
        G = padarray(im(:,:,2), [bottom_pad right_pad], 'replicate', 'post');%padarray(im(:,:,2), [bottom_pad right_pad], avg_chans(2), 'post');
        B = padarray(im(:,:,3), [bottom_pad right_pad], 'replicate', 'post');%padarray(im(:,:,3), [bottom_pad right_pad], avg_chans(3), 'post');
        im = cat(3, R, G, B);
    end
    padded_im = zeros(size(im,1), size(im,2));
    roi_pos = [context_xmin, context_ymin, context_xmax-context_xmin+1, context_ymax-context_ymin+1];
    xs = context_xmin : context_xmax;
    ys = context_ymin : context_ymax;

    im_patch = im(ys, xs, :);
    %im_patch = imresize(im_patch, [win_sz(1) win_sz(2)] );
end