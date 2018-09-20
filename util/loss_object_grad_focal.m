function [loss, delta] = loss_object_grad_focal(pred, label)

%%
% loss1 = abs(pred - label); %pred_label (0.9-1.1-> 0-1)
% loss2 = pred-label; %(-1,0)
% loss = -loss1.^2.*log10((1-(label-pred)));
% %loss(ind)=0;
% 
% %loss2(ind) = 0;
% delta = log10((pred-label)).*(-loss2)-(loss1.^2).*(log(10)./(1+pred-label) ); %for logistic loss
%% 
% soft_max1 = (6./(1+exp(7.*(0.9-label)))+1);
% label_exp = soft_max1/(min(soft_max1(:)));
% labels = label_exp.*label;
% labels = labels./max(labels(:));
% diff = abs(pred - label);
% exp_tmp = exp(label);
% a  = 6;
% factor_exp  = exp_tmp;%./max(exp_tmp(:));
% loss = factor_exp.*diff.^2/(1+exp(a.*(0.8-diff)));
% delta = -factor_exp.*(2.*diff./(exp(a.*(0.8-diff))+1)+ ...
%     a.*diff.^2.*exp(a.*(0.8-diff))./((exp(a.*(0.8-diff))+1).^2));
% %loss(ind)=0;
% loss2 = pred-label;
% %loss2(ind) = 0;
% %
%%
label_exp = exp(1.6*label);
labels = label_exp.*label;
labels = labels./max(labels(:));
loss1 = abs(pred - label);
ind = find(loss1<0.1);
loss = loss1.^3.*labels.^2;
%loss(ind)=0;
loss2 = pred-label;
%loss2(ind) = 0;
delta = -labels.^2.*(loss2.^2); %for logistic lossdelta = labels.^2.*(loss2); %for logistic loss