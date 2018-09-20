function [newfea_map, eigenVectors, scores] = mypca(fea_map, num)

  [a,b,c] = size(fea_map);
  fea_map = reshape(fea_map,[a*b,c]); %num*dim
  [eigenVectors, scores, eigenValues] = pca(fea_map'); %,'econ'
  [ Yk, X, avsq ] = pcaApply( fea_map', eigenVectors, scores, num );
%fea_map = scores(:,1:num);
  newfea_map = reshape(Yk',[a,b,num]);

    