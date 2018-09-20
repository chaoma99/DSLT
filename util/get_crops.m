function [im_crop_z, padded_im, roi_pos, left_pad_z, top_pad_z, right_pad_z, bottom_pad_z] = get_crops(im, object, context_amount)
% -------------------------------------------------------------------------------------------------------------------
    %% Get exemplar sample
    % take bbox with context for the exemplar

    bbox = object;
    [cx, cy, w, h] = deal(bbox(1)+bbox(3)/2, bbox(2)+bbox(4)/2, bbox(3), bbox(4));
    wc_z = w + context_amount(1)*(w);
    hc_z = h + context_amount(2)*(h);
    [im_crop_z, padded_im,roi_pos,left_pad_z, top_pad_z, right_pad_z, bottom_pad_z] = get_subwindow_avg(im, [cy cx], ([hc_z wc_z])); %pos win
%     [im_crop_z, padded_im,roi_pos,left_pad_z, top_pad_z, right_pad_z, bottom_pad_z] =...
%         get_subwindow_avg1(im, [bbox(1) bbox(2) w h], [0 0], context_amount+1); %pos win
    
 
end