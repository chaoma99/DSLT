function revise_bilinear_layer( prototext_file, fea_sz, tmp_target_sz )
fidin1 = fopen(prototext_file);%fopen('fea_net1.prototxt'); % 
fidout1 = fopen('vgg_bilinear_layer1.prototxt','w'); %%fopen([video '_layer.prototxt'],'w'); %
i=0;
im_w = fea_sz(1);
im_h = fea_sz(2);
kernel_h = tmp_target_sz(1);
kernel_w = tmp_target_sz(2);
while ~feof(fidin1) % 
    i=i+1;
    tline=fgetl(fidin1); %
    if  i==7 
        len = length(num2str(im_w));
        tline(12:12+len-1) = num2str(im_w);
        fprintf(fidout1,'%s\n',tline); % 
    elseif i==8 
        len = length(num2str(im_h));
        tline(12:12+len-1) = num2str(im_h);
        fprintf(fidout1,'%s\n',tline); % 
    elseif  i==10
        len = length(num2str(kernel_h));
        tline(11:11+len-1) = num2str(kernel_h);
        fprintf(fidout1,'%s\n',tline); % 
    elseif  i==11 
        len = length(num2str(kernel_w));
        tline(11:11+len-1) = num2str(kernel_w);
        fprintf(fidout1,'%s\n',tline); % 
    else
        fprintf(fidout1,'%s\n',tline); % 
    end
end
fclose(fidout1);