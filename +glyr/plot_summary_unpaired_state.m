function fig =  plot_summary_unpaired_state(mtab,roi_type,state, do_save,out_path)
% make a summary plot with the activity in all fovs and behaviour
% states. Include total time and number of rois

if nargin < 2,roi_type = "neurons"; end
if nargin < 3, state = "Run"; end
if nargin < 4, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);

% Get only neurons (default)/astrocytes
if roi_type == "neurons"
    tab = tab(startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "ND",:) = [];
else
    tab = tab(~startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "Gp",:) = [];
end

if isempty(tab), return, end
% Get rid of the 'Post-stimulation' state
tab(tab.exp_state == "Post-Stimulation",:) = [];

% Get total number of rois of each type
rois_t = unique(tab.roi_type);
tab_base = tab(tab.exp_state == "Baseline",:);
n_b = unique(tab_base.roi_short_name);
tab_stim = tab(tab.exp_state == "Stimulation",:);
n_s = unique(tab_stim.roi_short_name);

rois_b = zeros(1,numel(rois_t));
rois_s = zeros(1,numel(rois_t));
for r = 1:length(rois_t)
    rt = rois_t(r);
    if rt == "NS", rt = "NS "; end
    rois_b (r) = sum(contains(n_b,rt));
    rois_s(r) = sum(contains(n_s,rt));
end
r_b = containers.Map(rois_t,rois_b);
r_s = containers.Map(rois_t,rois_s);

% Get event frequency in secs and mins
tab = glyr.get_event_freq(tab);
tab.events_min = tab.events_sec * 60;

% get rid of rois w/o events
tab_both = tab(tab.events_min ~= 0,:);
tab_both(tab_both.category == "spikes_prob",:) = [];


if isempty(tab_both), fig = []; return, end
%% Plots
exp_state = ["Baseline","Stimulation"]; %["Baseline","Stimulation","Post-Stimulation"]
n_type = unique(tab_both.roi_type);

fig = figure('Position',[520 30 1533 1307],'Name',...
    "Summary_Upaired " + state + " " + unique(tab.exp_category));
layout = tiledlayout(1,2,'TileSpacing','compact');
title(layout,"Summary " + state + " " + unique(tab.exp_category))

% !!!! Important. Sort the table so that the boxplot plots the different
% experimental states in the same order (Baseline in the left)
tab_both = sortrows(tab_both,'exp_state','ascend');

hold on
warning off
for j = 1:numel(n_type)
    % Plot events/min for each RoI type (NS,NS-dnt,Np)-(AS,AE,AP)
    nexttile();
    nb = unique(tab_both.roi_short_name(tab_both.roi_type == n_type(j) & ...
        tab_both.exp_state == exp_state(1)));
    nb = numel(nb);
    ns = unique(tab_both.roi_short_name(tab_both.roi_type == n_type(j) & ...
        tab_both.exp_state == exp_state(2)));
    ns = numel(ns);
    tb = r_b(n_type(j));
    ts =  r_s(n_type(j));
    boxplot(tab_both.events_min(tab_both.roi_type == n_type(j)),...
        tab_both.exp_state(tab_both.roi_type == n_type(j)))
    rate_b = round(nb/tb,2);
    rate_s = round(ns/ts,2);
    if isnan(rate_b), rate_b = 0; end
    if isnan(rate_s), rate_s = 0; end
    title(n_type(j) + ...
        " Events rois w/ events in baseline or stimulation", "RoIs: " + ...
        "Baseline: " +  nb + "/" + tb + "  rate: " + rate_b + ...
        "  Stimulation: " + ns + "/" + ts + "  rate: " + rate_s )
    ylabel("Events/min")
end
warning on

% Plot time in each state
fovs = string(unique(double(tab_both.fov),'sorted'));
f = cell(length(fovs),2);
for i = 1:length(exp_state)
    f (:,i)= arrayfun(@(s) unique(tab_both.total_sec(tab_both.fov == s &...
        tab_both.exp_state == exp_state(i))),...
        fovs,'UniformOutput',false);
end

idx = cellfun(@isempty,f);
f(idx) = {0};
f = cell2mat(f);

% contribution to time of each fov
state_time = sum(f);
rate_time = round(f./state_time,2);
axt = nexttile(4,[1,3]);
if numel(fovs) == 1
    br = bar(axt,1:numel(fovs),f);
    xtips = br(1).XEndPoints;
    xtips2 = br(2).XEndPoints;
else
    br = bar(axt,1:numel(fovs),f,'stacked');
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
xticks(1:numel(fovs))
xticklabels(fovs)
xlabel("FoVs")
ylabel("Time (secs)")
legend(exp_state,'Location','best')

% Plots number or each roi type in each fov
% tab_both = tab_both(tab_both.exp_state == "Baseline",:);
rois= zeros(numel(fovs),3);
pos = 8;
for s = 1:length(exp_state)
    for i = 1:numel(fovs)
        for j = 1:numel(n_type)
            rois(i,j) = height(tab_both(tab_both.fov == fovs(i)...
                & tab_both.exp_state == exp_state(s) & ...
                tab_both.roi_type == n_type(j),:));
        end
    end
    n_rois = sum(rois);
    rate_rois = round(rois./n_rois,3);
    
    axt2 = nexttile(pos,[1,3]);
    pos = pos + 3;
    
    % Change color of bars by roi type
    colors = [1,0,0;0.8,0,0;1,1,0.1;0,1,0;0.4,0.6,0.4;0.4,0.8,0.6];
    colors = num2cell(colors,2);
    r_types = ["NS","NS-dnt","Np","AS","AE","AP"];
    r_colors = containers.Map(r_types,colors);
    
    if numel(fovs) == 1
        br2 = bar(axt2,1:numel(fovs),rois);
        xtips = [br2.XEndPoints];
        ytips = [br2.YEndPoints];
        labels = string(rate_rois);
        text(xtips,ytips,labels,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        for i = 1:numel(n_type)
            br2(i).FaceColor = r_colors(n_type(i));
        end
    else
        br2 = bar(axt2,1:numel(fovs),rois,'stacked');
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
    title("RoIs by FoV " + exp_state(s))
    xticks(1:numel(fovs))
    xticklabels(fovs)
    xlabel("FoVs")
    ylabel("Number of RoIs")
    legend(n_type,'Location','best')
end

if do_save
    if  nargin == 5 && ~isempty(out_path)
        p = out_path;
    else
        p = "/Volumes/GlyR/GlyR project/Plots/Activity_summary/Unpaired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filename = roi_type + "/plots/events_unpaired_summary_" + ...
        state + "_" + unique(tab.exp_category);
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-dpng');
    delete(fig)
    save(filename,'tab_both')
    
end
end