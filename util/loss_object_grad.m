function [loss, delta] = loss_object_grad(pred, label)
%% return loss and gradient


label_exp = exp(1.6*label);
labels = label_exp.*label;
labels = labels./max(labels(:));
diff = abs(pred - label);
a  = 10; 
c = 0.2;
a1 =labels.^2;
a2 = diff.^2;
a3 = 1.0./(1+exp(a.*(c-abs(diff))));
loss =a1.*a2.*a3;
delta = -labels.^2.*(2.*diff./(exp(a.*(c-diff))+1)+ ...
     a.*diff.^2.*exp(a.*(c-diff))./((exp(a.*(c-diff))+1).^2));
 %delta(delta>0)=0;
%%


