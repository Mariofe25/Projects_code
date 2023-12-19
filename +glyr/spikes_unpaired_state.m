function fig = spikes_unpaired_state(mtab,state, do_save,out_path)
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

% Get total number of rois of each type
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


dt = unique(tab.trace_dt);
tab.spikes_sec = cellfun(@(s) s/dt,tab.trace,'UniformOutput',false);
tab.spikes_mean = cellfun(@(s) mean(s,'omitnan'),tab.spikes_sec);
tab.spikes_std = cellfun(@(s) std(s,'omitnan'),tab.spikes_sec);

% terminate if no rois available
if isempty(tab), fig = []; return, end

%% Plots
exp_state = ["Baseline","Stimulation"]; %["Baseline","Stimulation","Post-Stimulation"]
n_type = unique(tab .roi_type);

fig = figure('Position',[520 30 1533 1307],'Name',...
    "Summary_Upaired " + state + " " + unique(tab.exp_category));
layout = tiledlayout(1,2,'TileSpacing','compact');
title(layout,"Summary " + state + " " + unique(tab.exp_category))

% !!!! Important. Sort the table so that the boxplot plots the different
% experimental states in the same order (Baseline in the left)
tab = sortrows(tab,'exp_state','ascend');

hold on
warning off
% Plot spikes/s 
nexttile();
nb = unique(tab.roi_short_name(tab.exp_state == exp_state(1)));
nb = numel(nb);
ns = unique(tab.roi_short_name(tab.exp_state == exp_state(2)));
ns = numel(ns);
tb = r_b(n_type);
ts =  r_s(n_type);
boxplot(tab.spikes_mean,tab.exp_state)
rate_b = round(nb/tb,2);
rate_s = round(ns/ts,2);
if isnan(rate_b), rate_b = 0; end
if isnan(rate_s), rate_s = 0; end
title(n_type + ...
    " Spikes/s in baseline or stimulation", "NS: " + ...
    "Baseline: " +  nb + "/" + tb + "  rate: " + rate_b + ...
    "  Stimulation: " + ns + "/" + ts + "  rate: " + rate_s )
ylabel("Events/min")

warning on

% Plot time in each state
fovs = string(unique(double(tab.fov),'sorted'));
f = cell(length(fovs),2);
for i = 1:length(exp_state)
    f (:,i)= arrayfun(@(s) unique(tab.total_sec(tab.fov == s &...
        tab.exp_state == exp_state(i))),...
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
% tab = tab(tab.exp_state == "Baseline",:);
rois= zeros(numel(fovs),3);
pos = 8;
for s = 1:length(exp_state)
    for i = 1:numel(fovs)
        for j = 1:numel(n_type)
            rois(i,j) = height(tab(tab.fov == fovs(i)...
                & tab.exp_state == exp_state(s) & ...
                tab.roi_type == n_type(j),:));
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

% Save plot
if do_save
    if  nargin == 5 && ~isempty(out_path)
        p = out_path;
    else
        p = "/Volumes/GlyR/GlyR project/Plots/Spikes_summary/Unpaired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filename = "/plots/spikes_unpaired_summary_" + ...
        state + "_" + unique(tab.exp_category);
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-depsc');
    delete(fig)
%     save(filename,'tab')
end


%% Table
t = tab(:,{'seg_category','roi_type','roi_short_name','exp_state','spikes_mean'});
    
t =  sortrows(t,{'exp_state','spikes_mean'},'ascend');

if do_save
    if  nargin == 5 && ~isempty(out_path)
        p = out_path;
    else
        p = "/Volumes/GlyR/GlyR project/Plots/Spikes_summary/Unpaired";
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
    end
    filename = "/tabs/spikes_unpaired_summary_" + ...
        state + "_" + unique(tab.exp_category) + "_" + "NS";
    filename = fullfile(p,filename);
    begonia.path.make_dirs(filename);
    writetable(t,filename,'FileType','spreadsheet');
end
end