function imgs = my_data_augmentation(img)
%shifting_value = [100,    0, -100,    0; 0,   100,    0, -100];
%center_img = center_crop(original_img, input_width, input_height, shifting_value(1,i), shifting_value(2,i));
%img = imread('/home/ying/1.jpg');
%rotation_angle = [-45, -30,-20,-10,10,20,30,45];
imgs=cell(1,1);%6+flip+gaussian
idx =0;
%for i =1:size(rotation_angle,2)
%    idx = idx+1;
%   img1 = imrotate(img,rotation_angle(i),'bicubic','crop');
%   imgs{idx,1} = img1;
   %figure,imshow(mat2gray(img1))
%end

g_sigma =[10,5,1,0.1];

for i =1:size(g_sigma,2)
    idx = idx+1;
    w = fspecial('gaussian',[5 5],g_sigma(i));
    im2 = imfilter(img,w);
    imgs{idx,1}=im2;
    %figure,imshow(mat2gray(im2))
end

im3 = fliplr(img);
for i =1:3
    idx = idx+1;
    imgs{idx,1} = im3;
end
%figure,imshow(mat2gray(im3))
