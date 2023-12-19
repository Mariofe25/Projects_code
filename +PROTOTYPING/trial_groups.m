%% find trials with rois and wheel traces
%  trials = get_trials_from_data(data)

trials_g = unique(data.tab.group_id);

trials = cell(1,length(trials_g));

for i = 1:length(trials)
    
    trials{i} = data.by_group_and_cat(string(trials_g(i)), ["roitrace", "wheel"], 1/15,"trim");
    trials{i}= data.tag_to_column(trials{i}, "roi_group", @categorical);
    trials{i}= data.tag_to_column(trials{i}, "mouse", @categorical);
    trials{i}= data.tag_to_column(trials{i}, "state", @categorical);

    if ~any(ismember(trials{i}.category, "roitrace")) || ~any(ismember(trials{i}.category, "wheel"))
        
        trials{i} = [];
        
    end
end

trials(cellfun('isempty',trials)) = [];

%% Plot heatmaps and wheel

for i = 1:length(trials)
figure()
sgtitle(string(trials{i}.group_id(1)));
xax = trials{i}.delta_time(1)*(1:length(trials{i}.trace{1}));
xax = xax';
subplot(2,1,1)
roi_traces = trials{i}.trace(trials{i}.category == "roitrace");
imagesc(horzcat(roi_traces{:})');
title('RoI signals over time (df/f_0)');
colormap(begonia.colormaps.magma)

% colorbar('southoutside')
caxis([0 1])
ylabel('RoI (#)');
xticklabels(round(xax(xticks)));
xlabel('s')

subplot(2,1,2)

wheel_trace = (trials{i}.trace(trials{i}.category == "wheel"));
plot(wheel_trace{:})
title('wheel data')
ylabel('d/s')
xx = xticks;
xticklabels(round(xax(1:xx(3)-xx(2):xx(end))))
xlabel('s')
xlim([0 length(wheel_trace{:})])
end