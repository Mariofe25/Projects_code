function total_rois = get_nrois(mtab)
% get total number of unique rois by roi type, from a multitable
mtab(ismissing(mtab.roi_short_name),:) = [];
rois_t = unique(mtab.roi_type);
n_id = unique(mtab.roi_short_name);
rois_total = zeros(1,numel(rois_t));
for r = 1:length(rois_t)
    rt = rois_t(r);
    if rt == "NS", rt = "NS "; end
    rois_total(r) = sum(contains(n_id,rt));
end
total_rois = containers.Map(rois_t,rois_total);