close all;
%for cross entropy loss
x = 0.001:0.001:1;
y = -log(x);
figure(1),plot(x,y,'b-');
y1 = - (1-x).^(0.5).*log(x);
y2 = -(1-x).*log(x);
y3 = -(1-x).^2.*log(x);
hold on,
plot(x,y1,'y-');
plot(x,y2,'g-');
plot(x,y3,'k-');
%for L2 loss
x1 = zeros(size(x));
th = 0.1
for i =1:size(x,2)
    if x(1,i)>=th
        x1(1,i)=x(1,i);
    end
end
figure(2),
plot(x,x.^2,'r-')
hold on,
plot(x,x1.^2,'b-')
%y4 =  



