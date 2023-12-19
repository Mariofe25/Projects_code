function tab = check_roi_dim(tss)
n_rois = zeros(length(tss),1);
right_dim = cell(length(tss),1);
ast_rois = zeros(length(tss),1);
neu_rois = zeros(length(tss),1);

total_ast_rois = zeros(length(tss),1);
total_neu_rois = zeros(length(tss),1);
total_rois = zeros(length(tss),1);

for i = 1:length(tss)
    dim = tss(i).img_dim;
    right_dim{i} = dim;

    roi_tab = tss(i).load_var('roi_table');
    rois_dim = cell2mat(cellfun(@(s) size(s), roi_tab.mask, 'UniformOutput',false));
    n_rois(i) = sum(rois_dim(:,1) ~= dim(1));
    idx = find(rois_dim(:,1) ~= dim(1));
    ast_idx = find(roi_tab.channel == 1);
    neu_idx = find(roi_tab.channel == 2);

    ast_rois(i) = sum(ismember(idx,ast_idx));
    neu_rois(i) = sum(ismember(idx,neu_idx));

    total_ast_rois(i) = height(roi_tab(roi_tab.channel == 1,:));
    total_neu_rois(i) = height(roi_tab(roi_tab.channel == 2,:));
    total_rois(i) = height(roi_tab);
end

prct_ast = ast_rois./total_ast_rois *100;
prct_neu = neu_rois./total_neu_rois *100;
ts_name = string({tss.name})';
tab = table(ts_name,right_dim,n_rois,ast_rois,neu_rois,total_ast_rois,...
    total_neu_rois,total_rois,prct_ast,prct_neu);
end