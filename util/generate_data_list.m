data_list = cell(4,2);
num = zeros(4, 2);
for i = iter_num : -1 : 1
data = load(['data/' num2str(i) '.mat']);
l_id = double(data.reward_t>0.5) + 1;
data_list{data.action_id_t, l_id} = [data_list{data.action_id_t, l_id} i];
num(data.action_id_t, l_id) = num(data.action_id_t, l_id)+1;
if mod(i,100)==0 fprintf('i = %d\n',i); end
if min(num(:)) > buffer_sz
    break;
end

end