function astrocytes_summary_paired_state(mtab,state, do_save)
% make a summary table with the tabning state in each fov and behaviour
% state. Include total time and number or rois
if nargin < 2, state = "tab"; end
if nargin < 3, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);

% FoVs w/ tab segments
fovs = unique(tab.fov);
n_fovs = numel(fovs);

% Get only neurons
tab = tab(~startsWith(tab.roi_type,"N"),:);
tab(tab.roi_type == "Gp",:) = [];

% Remove rois w/o event in all states
n_id = unique(tab.roi_short_name);
for i = 1:numel(n_id)
    roi = [tab.events{tab.roi_short_name == n_id(i)}];
    if isempty(roi)
        tab(tab.roi_short_name == n_id(i),:) = [];
    end
end

% Get event frequency in secs and mins
tab = glyr.get_event_freq(tab);
tab.events_min = tab.events_sec * 60;

% Get only fovs with events in baseline or in stimulation state
tab_base = unique(tab.fov(tab.exp_state == "Baseline"));
tab_stim = unique(tab.fov(tab.exp_state == "Stimulation"));

tab_both = ismember(tab_base,tab_stim);
tab_fovs = tab_base(tab_both);
tab_both = arrayfun(@(s) tab(tab.fov == s,:),tab_fovs,'UniformOutput',false);
tab_both = vertcat(tab_both{:});

if isempty(tab_both), return, end

% Plots
exp_state = ["Baseline","Stimulation","Post-Stimulation"];
n_type = unique(tab_both.roi_type);
fig = figure('Position',[1000 152 969 1185],'Name',...
    "Summary " + state + " " + unique(tab.exp_category));
layout = tiledlayout(4,2,'TileSpacing','compact');
title(layout,"Summary " + state + " " + unique(tab.exp_category))
hold on
warning off
for j = 1:numel(n_type)    
    % Plot events/min for each RoI type (AS,AE,AP)
    nexttile();
    n = unique(tab_both.roi_short_name(tab_both.roi_type == n_type(j)));
    n = numel(n);
    boxplot(tab_both.events_min(tab_both.roi_type == n_type(j)),...
        tab_both.exp_state(tab_both.roi_type == n_type(j)))
    title(n_type(j) + ...
        " Events rois w/ events in baseline and stimulation", "RoIs: " + n)
    ylabel("Events/min")
    xticklabels(exp_state)
    
    % Plot % activity change of each RoI type
    ax2 = nexttile();
    hold on
    b = tab_both.events_min(tab_both.roi_type == n_type(j) & ...
        tab_both.exp_state == "Baseline");
    s = tab_both.events_min(tab_both.roi_type == n_type(j) & ...
        tab_both.exp_state == "Stimulation");
    total = numel(b);
    comp = s > b;
    comp_2 = s == b;
    comp_3 = s < b;
    prct_g = sum(comp)/total;
    prct_e = sum(comp_2)/total;
    prct_l = sum(comp_3)/total;
    bar(ax2,[prct_g,prct_e,prct_l])
    ylabel("% change")
    title(n_type(j) + " Change percentage Baseline - Stimulation")
    xticks(1:3)
    xticklabels(["Increase","No Change", "Decrease"])
end
warning on

% Plot state time in each FoV
f = cell(length(tab_fovs),1);
for i = 1:length(exp_state)
f (:,i)= arrayfun(@(s) unique(tab_both.total_sec(tab_both.fov == s &...
    tab_both.exp_state == exp_state(i))),...
   tab_fovs,'UniformOutput',false);
end

for k = 1:length(tab_fovs)    
    if isempty(f{k,3})
        f{k,3} = 0;
    end
end
f = cell2mat(f);
axt = nexttile(7,[1,2]);
bar(axt,f,'grouped')
title("tabning time in each experimental state")
xticks(1:numel(tab_fovs))
xticklabels(tab_fovs)
xlabel("FoVs")
ylabel("Time (secs)")
legend(exp_state,'Location','best')

if do_save
    filename = sprintf("/Volumes/GlyR/GlyR project/Plots/Activity_summary/tab_summary_" + ...
        state + "_" + unique(tab.exp_category));
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-dpng');
    delete(fig)
end
end