clear;
close all;
sz= 40;
[rs] = 0:0.01:sz;%ndgrid((1:sz) - floor(sz/2));
sigma = 0.001;
labels = gaussmf(rs, [0.5 5]); 
%labels = exp(-0.5 / sigma^2 * (rs.^2 ));
figure,plot(rs,labels,'b');
labels1 = exp(labels);
hold on,plot(rs,labels1.*labels,'r');