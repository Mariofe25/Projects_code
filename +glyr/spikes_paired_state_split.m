function fig = spikes_paired_state_split(mtab,state, do_save,out_path)
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
layout = tiledlayout(1,2,'TileSpacing','compact');
title(layout,"Summary " + state + " " + unique(tab.exp_category))
hold on
warning off

% Plot spikes/s
n = unique(tab_both.roi_short_name);
n = numel(n);
t = r_total(n_type);

% difference baseline vs stimualtion
b = round(tab_both.spikes_mean(tab_both.exp_state == "Baseline"),2);
s = round(tab_both.spikes_mean(tab_both.exp_state == "Stimulation"),2);

total = numel(b);
comp = s > b;
comp_2 = s == b;
comp_3 = s < b;

% ratio 
ds_d = (s-b)./b;

in_25 = round(ds_d,1) >= 0.25;
dc_25 = round(ds_d,1) <= -0.25;
no_chg = round(ds_d,1) > -0.25 & round(ds_d,1) < 0.25;

% pr_in = sum(in_25)/total;
% pr_dc = sum(dc_25)/total;
% pr_ncg = sum(no_cg)/total;

st = tab_both.roi_short_name(tab_both.exp_state == "Stimulation");
incr = tab_both(ismember(tab_both.roi_short_name,st(in_25)),:);
dc = tab_both(ismember(tab_both.roi_short_name,st(dc_25)),:);
no_ch = tab_both(ismember(tab_both.roi_short_name,st(no_chg)),:);

r_in = ds_d(in_25);
r_dc = ds_d(dc_25);

ax_inc = nexttile();
boxchart(categorical(incr.exp_state),incr.spikes_mean)
ylabel("Spikes/s")
title(n_type + " Spikes/s probability - Increase (25%)")
xticklabels(exp_state)

incr_tab = make_tab(incr);

ax_dc = nexttile();
boxchart(categorical(dc.exp_state),dc.spikes_mean)
ylabel("Spikes/s")
title(n_type + " Spikes/s probability - Decrease (25%)")
xticklabels(exp_state)

dc_tab = make_tab(dc);

no_ch_tab = make_tab(no_ch);

% Save plot
if do_save
    if  nargin == 5 && ~isempty(out_path)
        p = out_path;
    else
        p = "/Volumes/GlyR/GlyR project/Plots/Spikes_summary/Paired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filenamen = "/plots/spikes_paired_summary_" + ...
        state + "_" + unique(tab.exp_category);
    filename = filenamen + "_split_incr_dcr";
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-depsc');
    delete(fig)

    fl = "/tabs/spikes_paired_summary_" + ...
        state + "_" + unique(tab.exp_category);

    file_incr = fl + "_increase.xlsx";
    incr_name = fullfile(p,file_incr);
    begonia.path.make_dirs(filename);
    writetable(incr_tab,incr_name)

    file_dc = fl + "_decrease.xlsx";
    dc_name = fullfile(p,file_dc);
    begonia.path.make_dirs(filename);
    writetable(dc_tab,dc_name)

    file_nc = fl + "_no_change.xlsx";
    dc_name = fullfile(p,file_nc);
    begonia.path.make_dirs(filename);
    writetable(no_ch_tab,dc_name)
end
end

function tab_pair = make_tab(tab_both)
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
end