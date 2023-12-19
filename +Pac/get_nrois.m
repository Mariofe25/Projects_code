function total_rois = get_nrois(mtab)
% get total number of unique rois by roi type, from a multitable
mtab(ismissing(mtab.roi_id),:) = [];
rois_t = unique(mtab.roi_type);
[~,idx] = unique(mtab.roi_id);
rois_type = mtab.roi_type(idx);
rois_total = cellfun(@(p) sum(rois_type == p),rois_t);
total_rois = containers.Map(rois_t,rois_total);
end