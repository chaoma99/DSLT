function revise_prototxt1(video, prototext_file, im_size )
fidin = fopen(prototext_file); % fopen(prototext_file);%
fidout = fopen([video '_fea_net.prototxt'],'w'); %
i=0;
im_w = im_size(1);
im_h = im_size(2);
while ~feof(fidin) % 
    i=i+1;
    tline=fgetl(fidin); %
    if  i==7 
        len = length(num2str(im_w));
        tline(12:12+len-1) = num2str(im_w);
        fprintf(fidout,'%s',tline); % 
    end
    if i==8
        len = length(num2str(im_h));
        tline(12:12+len-1) = num2str(im_h);
        fprintf(fidout,'%s\n',tline); % 
    else
        fprintf(fidout,'%s\n',tline); % 
    end
end
fclose(fidout);