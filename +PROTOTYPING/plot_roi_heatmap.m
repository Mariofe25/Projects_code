function plot_roi_heatmap(trial,time)

% load RoIs:
rois = (trial.trace(trial.category == "roitrace"));
rois = cell2mat(rois');
%     if length(rois) < 1; return; end

% plot each group separartely in a heatmap:
roi_groups = unique(trial.roi_group);
roi_groups = char(roi_groups);
roi_groups = rmmissing(roi_groups);
roi_groups = string(roi_groups);

hmap = [];

grp_idx = 1;

for i = 1:length(roi_groups)
    group = roi_groups(i);
    group_trace_idxs = rmmissing(trial.roi_group) == string(group);
    group_traces = rois(:,group_trace_idxs);
    
    grp_idx(end+1) = grp_idx(end) + (size(group_traces, 2));
    
    hmap(:,grp_idx(end-1):grp_idx(end) - 1) = group_traces;
end

% plot RoIs:
imagesc(hmap');
colormap(begonia.colormaps.magma);
caxis([0 0.3]);
title([char(trial.group_id(1)) ' : RoIs \deltaf/f'])
ylabel('RoIs')
xlabel('Time (s)')
xticklabels(round(time(xticks)))


% mark the groups:
yticks(grp_idx);
yticklabels(roi_groups);

for y = grp_idx
    line([0 300], [y y] - 0.5, 'Color',[1 1 1], 'LineWidth', 0.5);
end

colorbar('southoutside')

end