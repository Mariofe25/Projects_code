function tab = random_session(mtab)
% Randomly select sessions from multitab. (select only one entity per fov)

n =  unique([mtab.entity,mtab.fov],'rows','stable');

[~,~,gg] = unique(n(:,2),'stable');

g = unique(gg,'stable');
for i = 1:length(g)
    d{i} = find(gg == g(i));   
end

idx = cellfun(@(s) s(randperm(length(s),1)),d);
a_idx = n(idx)';
tab = mtab(ismember(mtab.entity,a_idx),:);
% % random selection (another option would be to use randi w/ min max input)
% idx = cellfun(@(s) datasample(s,1),d);
% 
% ses = ses(idx,1);
% 
% tab_idx = arrayfun(@(s) mtab.entity == s,ses,'UniformOutput',false);
% tab_idx = logical(sum(horzcat(tab_idx{:}),2));
% 
% tab = mtab(tab_idx,:);
end


% it would have been easier too directly select a random tseries of each
% fov and load its mtab...