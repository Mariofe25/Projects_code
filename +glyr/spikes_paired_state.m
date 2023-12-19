function fig = spikes_paired_state(mtab,state, do_save,out_path)
% make a summary plt with the activity in all fovs and behaviour
% states. Include total time and number of rois
if nargin < 2, state = "Run"; end
if nargin < 3, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);
tab = tab(tab.category == "spikes_prob",:);

tab(tab.exp_state == "Post-Stimulation",:) = [];

% Get only fovs with events in baseline or in stimulation state
tab_base = unique(tab.fov(tab.exp_state == "Baseline"));
tab_stim = unique(tab.fov(tab.exp_state == "Stimulation"));

tab_both = ismember(tab_base,tab_stim);
tab_fovs = tab_base(tab_both);
tab_fovs = string(sort(double(tab_fovs)));
tab_both = arrayfun(@(s) tab(tab.fov == s,:),tab_fovs,'UniformOutput',false);
tab_both = vertcat(tab_both{:});

% Get total number of rois of each type
r_total = glyr.get_nrois(tab_both);

tab_fovs = unique(tab_both.fov,'stable');

dt = unique(tab_both.trace_dt);
tab_both.spikes_sec = cellfun(@(s) s/dt,tab_both.trace,'UniformOutput',false);
tab_both.spikes_mean = cellfun(@(s) mean(s,'omitnan'),tab_both.spikes_sec);
tab_both.spikes_std = cellfun(@(s) std(s,'omitnan'),tab_both.spikes_sec);

% terminate if no rois available
if isempty(tab_both), fig = []; return, end

%% Plots
exp_state = ["Baseline","Stimulation"];
n_type = unique(tab_both.roi_type);

fig = figure('Position',[1000 57 1561 1280],'Name',...
    "Spikes probability_Paired " + state + " " + unique(tab.exp_category));
layout = tiledlayout(3,3,'TileSpacing','compact');
title(layout,"Summary " + state + " " + unique(tab.exp_category))
hold on
warning off

% Plot spikes/s
nexttile();
n = unique(tab_both.roi_short_name);
n = numel(n);
t = r_total(n_type);
boxplot(tab_both.spikes_mean,tab_both.exp_state)
title(n_type + ...
    " NS Spikes/s in Baseline and Stimulation", "RoIs: " + ...
    n + "/" + t + "  rate: " + round(n/t,2))
ylabel("Spikes/s")
xticklabels(exp_state)

% Plot % activity change of each RoI type
ax2 = nexttile();
hold on
b = round(tab_both.spikes_mean(tab_both.exp_state == "Baseline"),2);
s = round(tab_both.spikes_mean(tab_both.exp_state == "Stimulation"),2);

total = numel(b);
comp = s > b;
comp_2 = s == b;
comp_3 = s < b;
prct_g = sum(comp)/total;
prct_e = sum(comp_2)/total;
prct_l = sum(comp_3)/total;

% Calculte change rate
ds_d = (s-b)./b;
% % %

in_25 = round(ds_d,1) >= 0.25;
dc_25 = round(ds_d,1) <= -0.25;
no_cg = round(ds_d,1) > -0.25 & round(ds_d,1) < 0.25;

pr_in = sum(in_25)/total;
pr_dc = sum(dc_25)/total;
pr_ncg = sum(no_cg)/total;

bar(ax2,[pr_in,pr_ncg,pr_dc])

ylabel("% change")
title(n_type + " Trend Spike prob Stimulation (25%)")
xticks(1:3)
xticklabels(["Increase","No Change", "Decrease"])

% st = tab_both.roi_short_name(tab_both.exp_state == "Stimulation");
% incr = tab_both(ismember(tab_both.roi_short_name,st(in_25)),:);
% dc = tab_both(ismember(tab_both.roi_short_name,st(dc_25)),:);

% r_in = ds_d(in_25);
% r_dc = ds_d(dc_25);

% Create a histogram showing the spike prob change stim vs baseline
ax3 = nexttile();
histogram(ax3,ds_d,'BinWidth',0.25);
title("Distribution spike probability change")
xlabel("rate change")
ylabel("number NS")

warning on

% Plot state time in each FoV
f = cell(length(tab_fovs),1);
for i = 1:length(exp_state)
    f (:,i)= arrayfun(@(s) unique(tab_both.total_sec(tab_both.fov == s &...
        tab_both.exp_state == exp_state(i))),...
        tab_fovs,'UniformOutput',false);
end
f = cell2mat(f);

% contribution to time of each fov
state_time = sum(f);
rate_time = round(f./state_time,2);
axt = nexttile(4,[1,3]);
if numel(tab_fovs) == 1
    br = bar(axt,1:numel(tab_fovs),f);
    xtips = br(1).XEndPoints;
    xtips2 = br(2).XEndPoints;
else
    br = bar(axt,1:numel(tab_fovs),f,'stacked');
    xtips = br.XEndPoints;
    xtips2 = xtips;
end
ytips = br(1).YEndPoints;
ytips2 = br(2).YEndPoints;
labels = string(rate_time(:,1)'); % "Baseline: " + string(rate_time(:,1)');
labels2 = string(rate_time(:,2)'); % "Stimulation: " + string(rate_time(:,2)');
text(xtips,ytips,labels,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
text(xtips2,ytips2,labels2,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')

title("Time in each experimental state by FoV")
xticks(1:numel(tab_fovs))
xticklabels(tab_fovs)
xlabel("FoVs")
ylabel("Time (secs)")
legend(exp_state,'Location','best')

% Plots number or each roi type in each fov
% Baseline and stimulation rows contains the same rois (BEFORE-AFTER). In order
% to count unique rois, take only the rows in baseline
tab_un = tab_both(tab_both.exp_state == "Baseline",:);
rois = zeros(numel(tab_fovs),3);
for i = 1:numel(tab_fovs)
    for j = 1:numel(n_type)
        rois(i,j) = height(tab_un(tab_un.fov == tab_fovs(i)...
            & tab_un.roi_type == n_type(j),:));
    end
end
n_rois = sum(rois);
rate_rois = round(rois./n_rois,2);

% Change color of bars by roi type
colors = [1,0,0;0.8,0,0;1,1,0.1;0,1,0;0.4,0.6,0.4;0.4,0.8,0.6];
colors = num2cell(colors,2);
r_types = ["NS","NS-dnt","Np","AS","AE","AP"];
r_colors = containers.Map(r_types,colors);

axt2 = nexttile(7,[1,3]);
if numel(tab_fovs) == 1
    br2 = bar(axt2,1:numel(tab_fovs),rois);
    xtips = [br2.XEndPoints];
    ytips = [br2.YEndPoints];
    labels = string(rate_rois);
    text(xtips,ytips,labels,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    for i = 1:numel(n_type)
        br2(i).FaceColor = r_colors(n_type(i));
    end
else
    br2 = bar(axt2,1:numel(tab_fovs),rois,'stacked');
    xtips = br2.XEndPoints;
    for i = 1:numel(n_type)
        br2(i).FaceColor = r_colors(n_type(i));
        ytips = br2(i).YEndPoints;
        rs = string(rate_rois(:,i))';
        labels = rs; % n_type(i) + " " + rs;
        if any(rate_rois(:,i) == 0)
            idx = rate_rois(:,i) == 0;
            labels(idx) = "";
        end
        text(xtips,ytips,labels,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
    end
end
title("RoIs by FoV")
xticks(1:numel(tab_fovs))
xticklabels(tab_fovs)
xlabel("FoVs")
ylabel("Number of RoIs")
legend(n_type,'Location','best')

% Save plot
if do_save
    if  nargin == 5 && ~isempty(out_path)
        p = out_path;
    else
        p = "/Volumes/GlyR/GlyR project/Plots/Spikes_summary/Paired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filename = "/plots/spikes_paired_summary_" + ...
        state + "_" + unique(tab.exp_category);
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-depsc');
    delete(fig)
end

%% Table
t = tab_both;
mouse = t.mouse(t.exp_state == "Baseline");
base = t.exp_state == "Baseline";
behav = t.seg_category(base,:);
roi_name = t.roi_short_name(base,:);
roi_type = t.roi_type(base,:);
spk_base = round(t.spikes_mean(t.exp_state == "Baseline",:),1);
spk_stim  = round(t.spikes_mean(t.exp_state == "Stimulation",:),1);

tab_pair = table(behav,mouse,roi_name,roi_type,spk_base,spk_stim);

tab_pair =  sortrows(tab_pair,{'spk_base','spk_stim'},'descend');

% tab with the 25% change 
ch_tab = array2table([pr_in,pr_ncg,pr_dc],"VariableNames",["Increase",...
    "No_change","Decrease"]);
if do_save
    if  nargin == 5 && ~isempty(out_path)
        p = out_path;
    else
        p = "/Volumes/GlyR/GlyR project/Plots/Spikes_summary/Paired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filename = "/tabs/spikes_paired_summary_" + ...
        state + "_" + unique(tab.exp_category) + "_" + "NS.xlsx";
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    writetable(tab_pair,filename,'FileType','spreadsheet');
    f_ch = "/tabs/Chnage_spikes_rate_" + ...
        state + "_" + unique(tab.exp_category) + "_" + "NS.xlsx";
    filename_2 = fullfile(p,f_ch);
    begonia.path.make_dirs(filename_2);
    writetable(ch_tab,filename_2,'FileType','spreadsheet');
end
end