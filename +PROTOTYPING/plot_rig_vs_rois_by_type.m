%  modify from knut

function plot_rig_vs_rois_by_type(trials,save)

if nargin < 2
    save = true;
end

% choose(create) a folder to save the plots
if save
    path = uigetdir;
end

% Plot data by group id
tic
for trial = trials
    trial =  trial{:};
    ts_name = string(trial.group_id(1));
    disp("Plotting: " + ts_name);
    try
        fig = plot_wheel_vs_rois_chart(trial);
        % save results:
        if save
            filename = [char(trial.group_id(1)),' activity_vs_rois_by_type'];
            outpng = fullfile(path, [filename '.png']);
            print(fig, outpng, '-r300', '-dpng');
            % clean up:
            delete(fig);
        end
    catch err
        disp(err.message)
        continue
    end
end
disp("Plotting done in " + toc + " s")
end

function fig = plot_wheel_vs_rois_chart(trial)

trace_cat = unique(trial.category);
trace_cat = string(trace_cat);
trace_cat = sort(trace_cat,'descend');
PLOT_ROWS = length(trace_cat);
if any(trace_cat == 'roitrace') || isequal(trace_cat,'roitrace')
    PLOT_ROWS = PLOT_ROWS + 2;
end

% Set rig plot labels (this could be implement as a function input argument)
ylabels = {'stim','px','Wheel (\delta ang.)','diameter in pixels'}';
titles = {'Whisker stim','Whisking','Locomotion','Pupil diameter'}';

% Select rig plots
cat_traces = {'whisker_log','whisker','wheel','pupil'}';
tab = table(cat_traces,titles,ylabels);
isx = ismember(tab.cat_traces,trace_cat);
tab = tab(isx,:);

% create figure
fig = figure('Position', [0 0 600*3 1200], 'InvertHardcopy', 'off');
fig.Color = 'white';
sgtitle(string(trial.group_id(1)))% + "       Mouse: " + unique(string(trial.mouse)) +...
   % "       State: " + (trial.state(5)));

% duration trial (all traces have the same time)
dt = trial.delta_time(5);
trace_length = (1:length(trial.trace{5}))';
time = dt*trace_length; 

% plot rig traces
if ~isempty(tab)
    for i = 1:height(tab)
        trace = trial.trace(trial.category == tab.cat_traces(i));
        subplot(PLOT_ROWS, 1, i);
        plot(trace{:}, 'Color', [0.3 0.3 0.3],'LineWidth',1);
        title(tab.titles(i))
        ylabel(tab.ylabels(i))
        yticklabels(yticks)
        % xx = xticks;
        % xx(1) = 1;
        % xx(end) = [];
        % xticklabels(round(time(xx)))
        xlim([0 length(time)])
        xlabel('Time (s)')
    end
end

% plot RoI heatmap:
if any(trace_cat == 'roitrace')
    ax = subplot(PLOT_ROWS, 1, PLOT_ROWS-2:PLOT_ROWS);
    % ax.Position = [0.13 0.015 0.7750 0.40];
    plot_roi_heatmap(ax,trial,time);
end
end

function plot_roi_heatmap(ax,trial,time)

% load RoIs:
rois = (trial.trace(trial.category == "roitrace"));
rois = cell2mat(rois');
%     if length(rois) < 1; return; end

% plot each group separartely in a heatmap:
roi_groups = unique(trial.roi_group);
roi_groups = rmmissing(roi_groups);
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
imagesc(ax, hmap');
colormap(begonia.colormaps.magma);
caxis([0 0.5]);
title('RoIs \deltaf/f')
ylabel('RoIs')
xlabel('Time (s)')
xlim([0 length(time)])
% xticklabels(round(time(xticks)))

% mark the groups:
yticks(grp_idx);
yticklabels(roi_groups);

for y = grp_idx
    line([0 300], [y y] - 0.5, 'Color',[1 1 1], 'LineWidth', 0.5);
end
colorbar('southoutside')

end
