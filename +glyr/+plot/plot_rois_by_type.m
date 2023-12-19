function plot_rois_by_type(trial)

tic

% choose(create) a folder to save the plots
disp("choose/create a folder to save the plots")
path = uigetdir;
disp("Plots will be save in " + path)

% plotting each trial
% for trial = trial(:)

%      trial =  trial{:};

ts_name = string(trial.group_id(1));

disp("Plotting: " + ts_name);

plot_rois_chart(trial,path)

% end

disp("Plotting done in " + toc + " s")

end

function plot_rois_chart(trial,path)


% create figure
fig = figure('Position', [0 0 600*4 1200], 'InvertHardcopy', 'off');
fig.Color = 'white';

% duration trial (all traces have the same time except airpuff if it exist, so
% take anyone except airpuff trace)
dt = trial.delta_time(1);
trace_length = (1:length(trial.trace{1}))';
time = dt*trace_length;

% plot RoI heatmap:
plot_roi_heatmap(trial,time);

% save results:
filename = [char(trial.group_id(1)),' activity_vs_rois_by_type'];
outpng = fullfile(path, [filename '.png']);
print(fig, outpng, '-r300', '-dpng');

end

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



