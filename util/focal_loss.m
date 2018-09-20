clc;
close all
clear;
load('mulmodal.mat');
%load('label.mat');
label=a;
x = size(label,1);
y = size(label,2);

xx=round(-(x/2):1:x/2-1);

yy=round(-(y/2):1:y/2-1);

[X,Y]=meshgrid(yy,xx);
%figure,mesh(Y,X,label)

figure,imshow(mat2gray(label))
[center_y, center_x, sind] = ind2sub(size(label),find(label == max(label(:)),1));
hold on, plot(center_x, center_y, '.','markersize',20);
low_label = label-min(label(:));
PAEC = (max(label(:))-min(label(:)))^2/(mean(mean(low_label.^2)));
%hLocalMax = vision.LocalMaximaFinder;
%hLocalMax.NeighborhoodSize = [7 7];
%bin_im = step(hLocalMax, label);%vision.LocalMaximaFinder(label);
%[zmax,imax,zmin,imin]= extrema2(label)
%bin_im = imregionalmax(label,18)
[xIn, yIn] = localMaximum(label,20);
for i =1:size(xIn,1)
    plot(yIn(i), xIn(i), '.','markersize',20);
end
value = label(xIn,yIn);
other_value = label(xIn,yIn);
order_value = sort(other_value(:),'descend');
 
figure(3), imshow(bin_im)

% label_exp = exp(label);
% labels = label_exp.*label;
% labels = labels./max(labels(:));
% figure(2),mesh(Y,X,labels)

% for i =1:10
%     for j=0.1:0.1:0.9
%     soft_max1 = (6./(1+exp(i.*(j-label)))+1);
%     labels1 = soft_max1.*label;
%     labels1 = labels1./max(labels1(:));
%     snr2  = exp(max(labels(:))-mean(labels(:)));
%     snr3 = exp(max(labels1(:))-mean(labels1(:)));
%     if (snr3-snr2)>0.001
%         fprintf('The value of i,j are %f,%f, value is %f \n', i,j, snr3);
% %         
%     end
% %figure(3),mesh(Y,X,labels1)
%     end
% end
%    snr2
%    snr1 = exp(max(label(:))-mean(label(:)))


