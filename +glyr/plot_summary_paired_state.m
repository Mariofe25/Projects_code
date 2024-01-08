function fig = plot_summary_paired_state(mtab,roi_type,state, do_save,out_path)
% make a summary plt with the activity in all fovs and behaviour
% states. Include total time and number of rois
if nargin < 2,roi_type = "neurons"; end
if nargin < 3, state = "Run"; end
if nargin < 4, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);

% FoVs w/ tab segments
%fovs = unique(tab.fov);
%n_fovs = numel(fovs);

% Get only neurons(default)/astrocytes
if roi_type == "neurons"
    tab = tab(startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "ND",:) = [];
else
    tab = tab(~startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "Gp",:) = [];
end

if isempty(tab), fig = []; return, end

% Get rid of the 'Post-stimulation' state
tab(tab.exp_state == "Post-Stimulation",:) = [];

% Get event frequency in secs and mins
tab = glyr.get_event_freq(tab);
tab.events_min = tab.events_sec * 60;

% Get only fovs with events in baseline or in stimulation state
tab_base = unique(tab.fov(tab.exp_state == "Baseline"));
tab_stim = unique(tab.fov(tab.exp_state == "Stimulation"));

tab_both = ismember(tab_base,tab_stim);
tab_fovs = tab_base(tab_both);
tab_fovs = string(sort(double(tab_fovs)));
tab_both = arrayfun(@(s) tab(tab.fov == s,:),tab_fovs,'UniformOutput',false);
tab_both = vertcat(tab_both{:});

if isempty(tab_both)
    return
end

% Get total number of rois of each type
rois_t = unique(tab_both.roi_type);
n_id = unique(tab_both.roi_short_name);
rois_total = zeros(1,numel(rois_t));
for r = 1:length(rois_t)
    rt = rois_t(r);
    if rt == "NS", rt = "NS "; end
    rois_total(r) = sum(contains(n_id,rt));
end
r_total = containers.Map(rois_t,rois_total);

% Remove rois w/o event in all experimental states
n_id = unique(tab_both.roi_short_name,'stable');
for i = 1:numel(n_id)
    roi = [tab_both.events{tab_both.roi_short_name == n_id(i)}];
    if isempty(roi)
        tab_both(tab_both.roi_short_name == n_id(i),:) = [];
    end
end

% remove spikes prob traces
tab_both(tab_both.category == "spikes_prob",:) = [];

tab_fovs = unique(tab_both.fov,'stable');
% terminate if no rois
if isempty(tab_both), fig = []; return, end 


%% Plots
exp_state = ["Baseline","Stimulation"]; 
n_type = unique(tab_both.roi_type);

fig = figure('Position',[1000 30 996 1307],'Name',...
    "Summary_Paired " + state + " " + unique(tab.exp_category));
layout = tiledlayout(5,2,'TileSpacing','compact');
title(layout,"Summary " + state + " " + unique(tab.exp_category))
hold on
warning off
for j = 1:numel(n_type)
    % Plot events/min for each RoI type (NS,NS-dnt,Np)-(AS,AE,AP)
    nexttile();
    n = unique(tab_both.roi_short_name(tab_both.roi_type == n_type(j)));
    n = numel(n);
    t = r_total(n_type(j));
    boxplot(tab_both.events_min(tab_both.roi_type == n_type(j)),...
        tab_both.exp_state(tab_both.roi_type == n_type(j)))
    title(n_type(j) + ...
        " Events rois w/ events in baseline or stimulation", "RoIs: " + ...
        n + "/" + t + "  rate: " + round(n/t,2))
    ylabel("Events/min")
    xticklabels(exp_state)
    
    % Plot % activity change of each RoI type
    ax2 = nexttile();
    hold on
    b = round(tab_both.events_min(tab_both.roi_type == n_type(j) & ...
        tab_both.exp_state == "Baseline"),2);
    s = round(tab_both.events_min(tab_both.roi_type == n_type(j) & ...
        tab_both.exp_state == "Stimulation"),2);
    
    % only active rois
    total = numel(b);
    comp = s > b;
    comp_2 = s == b;
    comp_3 = s < b;
    prct_g = sum(comp)/total;
    prct_e = sum(comp_2)/total;
    prct_l = sum(comp_3)/total;
    
    % all rois
    prct_g_all = sum(comp)/t;
    prct_e_all = sum(comp_2)/t + (t - total)/t;
    prct_l_all = sum(comp_3)/t;
    
    bar(ax2,[prct_g,prct_e,prct_l; prct_g_all,prct_e_all,prct_l_all]')
    legend(["Active RoIs", "All RoIs"])
   
    
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

f = cell2mat(f);
% contribution to time of each fov
state_time = sum(f);
rate_time = round(f./state_time,2);
axt = nexttile(7,[1,2]);
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

axt2 = nexttile(9,[1,2]);
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
        p = "/Volumes/GlyR/GlyR project/Plots/Activity_summary/Paired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filename = roi_type + "/plots/events_paired_summary_" + ...
        state + "_" + unique(tab.exp_category);
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-dpng');
    delete(fig)
    %save(filename,'tab_both')
end
end