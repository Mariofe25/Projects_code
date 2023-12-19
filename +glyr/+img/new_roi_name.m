function new_roi_name(tss,mtab)
import begonia.logging.log
if nargin < 2
    log(1,"Loading multitab")
    mtab = glyr.mtab_merge_states(tss);
end
tss_fovs = tss.load_var("RFOV");
tss_fovs = [tss_fovs{:}];
[~,fov_loc,~] = unique(tss_fovs,'stable');

rois_tabs = tss(fov_loc).load_var('roi_table');
rois_tabs = vertcat(rois_tabs{:});
rois_names = unique(rois_tabs.short_name,'stable');

log(1,"Identifying rois w/ repeated ids")
[reps,b,c] = glyr.img.check_roi_names(mtab);

while length(rois_names) ~= height(rois_tabs)  
if ~isempty(reps)
    log(1,"Generating new ids")
    glyr.img.reassingn_roi_id(tss,reps)
else    
    return
end
log(1,"Checking that ids are unique")
rois_tabs = tss(fov_loc).load_var('roi_table');
rois_tabs = vertcat(rois_tabs{:});
rois_names = unique(rois_tabs.short_name,'stable');
end
log(1,"All rois have unique ids. Done!")
end