function tab_summary_paired_state(mtab,rois_type,state, do_save,out_path)
if nargin < 2,rois_type = "neurons"; end
if nargin < 3, state = "Run"; end
if nargin < 4, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);

% FoVs w/ tab segments
%fovs = unique(tab.fov);
%n_fovs = numel(fovs);

% Get only neurons(default)/astrocytes
if rois_type == "neurons"
    tab = tab(startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "ND",:) = [];
else
    tab = tab(~startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "Gp",:) = [];
end

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

if isempty(tab_both), return; end

tab_both(tab_both.category == "spikes_prob",:) = [];

tab = tab_both;

% Get total number of rois of each type
rois_t = unique(tab.roi_type);
r_total = glyr.get_nrois(tab);
% n_id = unique(tab.roi_short_name);
% rois_total = zeros(1,numel(rois_t));
% for r = 1:length(rois_t)
%     rt = rois_t(r);
%     if rt == "NS", rt = "NS "; end
%     rois_total(r) = sum(contains(n_id,rt));
% end
% r_total = containers.Map(rois_t,rois_total);

% Remove rois w/o event in all experimental states
n_id = unique(tab_both.roi_short_name,'stable');
for i = 1:numel(n_id)
    roi = [tab_both.events{tab_both.roi_short_name == n_id(i)}];
    if isempty(roi)
        tab_both(tab_both.roi_short_name == n_id(i),:) = [];
    end
end

if isempty(tab_both),return; end

r_tot = glyr.get_nrois(tab_both);

% bootstrp(nsamples,@mean,mr');

for i = 1:length(rois_t)
    t = tab(tab.roi_type == rois_t(i),:);
    mouse = t.mouse(t.exp_state == "Baseline");
    base = t.exp_state == "Baseline";
    behav = t.seg_category(base,:);
    roi_name = t.roi_short_name(base,:);
    roi_type = t.roi_type(base,:);
    evs_base = round(t.events_min(t.exp_state == "Baseline",:),1);
    evs_stim  = round(t.events_min(t.exp_state == "Stimulation",:),1);

    tab_pair = table(behav,mouse,roi_name,roi_type,evs_base,evs_stim);

    tab_pair =  sortrows(tab_pair,{'evs_base','evs_stim'},'descend');

    tt = r_total(rois_t(i));

    b = round(tab_both.events_min(tab_both.roi_type == rois_t(i) & ...
        tab_both.exp_state == "Baseline"),2);
    s = round(tab_both.events_min(tab_both.roi_type == rois_t(i) & ...
        tab_both.exp_state == "Stimulation"),2);

    % only active rois
    total = numel(b);
    comp = s > b;
    comp_2 = s == b;
    comp_3 = s < b;

    % percentage change active rois
    prct_g = sum(comp)/total;
    prct_e = sum(comp_2)/total;
    prct_l = sum(comp_3)/total;

    % all rois
    prct_g_all = sum(comp)/tt;
    prct_e_all = sum(comp_2)/tt + (tt - total)/tt;
    prct_l_all = sum(comp_3)/tt;

    exp = array2table([prct_g,prct_e,prct_l;prct_g_all,prct_e_all,...
        prct_l_all],"VariableNames",["Increase","No change","Decrease"],...
        "RowNames",["Active","All"]);

    if do_save
        if  nargin == 5 && ~isempty(out_path)
            p = out_path;
        else
            p = "/Volumes/GlyR/GlyR project/Plots/Activity_summary/Paired";
            p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
        end
        filename = rois_type + "/tabs/events_paired_summary_" + ...
            state + "_" + unique(tab.exp_category) + "_" + rois_t(i) ;
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        writetable(tab_pair,filename,'FileType','spreadsheet');

        fn = rois_type + "/tabs/Summary_paired_rate_change_" + ...
            state + "_" + unique(tab.exp_category) + "_" + rois_t(i);
        fn = fullfile(p,fn);
        writetable(exp,fn,'FileType','spreadsheet');
    end
end
end