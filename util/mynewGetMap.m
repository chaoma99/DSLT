function map =  mynewGetMap(fea_sz, res_sz,  l_off, output_sigma_factor)
% sz = fea_sz([2,1]);
% [rs, cs] = ndgrid((0.5:sz(1)-0.5) - (sz(1)/2), (0.5:sz(2)-0.5) - (sz(2)/2));
% %output_sigma = sqrt(prod(location([3,4]))) * output_sigma_factor;
% sigma = [15 6]*0.6;%output_sigma_factor([2,1]);
% map = exp(-0.5 / sigma(1)^2 * (rs.^2 )).*exp(-0.5 / sigma(2)^2 * (cs.^2 ));
% %%map = map(sz(1)/2-fea_sz(1)/2: sz(1)/2+fea_sz(1)/2, sz(2)/2-fea_sz(2)/2: sz(2)/2+fea_sz(2)/2,: );
% %map1 = zeros(roi_sz([2,1]));
% %map1(roi_sz(2)/2-roi_sz(1)/2: roi_sz(2)/2-sz(1)/2+sz(1)-1,roi_sz(1)/2-sz(2)/2: roi_sz(1)/2-sz(2)/2+sz(2)-1) = map;
% map = imresize(map(:,:,1), [fea_sz(1), fea_sz(2)],'bilinear');
% map = (map - min(map(:))) / (max(map(:)) - min(map(:)) + eps);


sz = fea_sz([2,1]);
[rs, cs] = ndgrid((0.5:sz(1)-0.5) - (sz(1)/2), (0.5:sz(2)-0.5) - (sz(2)/2));
%output_sigma = sqrt(prod(location([3,4]))) * output_sigma_factor;
sigma = output_sigma_factor([2,1]);
map = exp(-0.5 *( (rs.^2 +cs.^2)./ sigma(1)^2)); %+  (cs.^2 )./ sigma(2)^2) );
%%map = map(sz(1)/2-fea_sz(1)/2: sz(1)/2+fea_sz(1)/2, sz(2)/2-fea_sz(2)/2: sz(2)/2+fea_sz(2)/2,: );
%map1 = zeros(roi_sz([2,1]));
%map1(roi_sz(2)/2-roi_sz(1)/2: roi_sz(2)/2-sz(1)/2+sz(1)-1,roi_sz(1)/2-sz(2)/2: roi_sz(1)/2-sz(2)/2+sz(2)-1) = map;
map = imresize(map(:,:,1), [res_sz(1), res_sz(2)],'bilinear');
map = (map - min(map(:))) / (max(map(:)) - min(map(:)) + eps);

