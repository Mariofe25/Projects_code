function [reps,ids,total_rois] = check_roi_names(mtab)

% Take only baseline experimental state
base = mtab(mtab.exp_state == "Baseline",:);

tab = unique(base(:,{'fov','roi_short_name'}),'stable'); % easy peasy
total_rois = height(tab);

% Find unique short roi id
[ids,loc] = unique(tab.roi_short_name,'stable');

l = 1:height(tab);
g = ismember(l,loc);
reps = tab(~g,:);

% out = unique(tab(setdiff((1:height(tab)),loc),:))

reps_fovs = unique(reps.fov,'stable');
reps_fovs = double(reps_fovs);

if isempty(reps)
    disp('All RoIs have unique IDs')
else
    disp('These FoVs have repeated short RoI IDs')
    s = sprintf('%d ',reps_fovs);
    disp(s)
end
end