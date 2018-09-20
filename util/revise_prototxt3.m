function revise_prototxt3(video, prototext_file, fea_sz, tmp_target_sz,res_sz )

fidin1 = fopen(prototext_file);%fopen('fea_net1.prototxt'); % 
fidout1 = fopen('adjust_layer_focal_loss1.prototxt','w'); %%fopen([video '_layer.prototxt'],'w'); %
i=0;
im_w = fea_sz(1);
im_h = fea_sz(2);
gt_w = res_sz(1);
gt_h = res_sz(2);
kernel_h = tmp_target_sz(1);
kernel_w = tmp_target_sz(2);
while ~feof(fidin1) % 
    i=i+1;
    tline=fgetl(fidin1); %
    if  i==7 
        len = length(num2str(im_w));
        tline(12:12+len-1) = num2str(im_w);
        fprintf(fidout1,'%s\n',tline); % 
     elseif i==12 % || i==13
        len = length(num2str(gt_w));
        tline(12:12+len-1) = num2str(gt_w);
        fprintf(fidout1,'%s\n',tline); %
     elseif i==13 % || i==13
        len = length(num2str(gt_h));
        tline(12:12+len-1) = num2str(gt_h);
        fprintf(fidout1,'%s\n',tline); %
    elseif i==8
        len = length(num2str(im_h));
        tline(12:12+len-1) = num2str(im_h);
        fprintf(fidout1,'%s\n',tline); % 
    elseif  i==18
        len = length(num2str(kernel_h));
        tline(11:11+len-1) = num2str(kernel_h);
        fprintf(fidout1,'%s\n',tline); % 
    elseif  i==19 
        len = length(num2str(kernel_w));
        tline(11:11+len-1) = num2str(kernel_w);
        fprintf(fidout1,'%s\n',tline); % 
    else
        fprintf(fidout1,'%s\n',tline); % 
    end
end
fclose(fidout1);
