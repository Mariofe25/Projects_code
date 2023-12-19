function fig =  tab_summary_unpaired_state(mtab,rois_type,state, do_save,out_path)
% make a summary plot with the activity in all fovs and behaviour
% states. Include total time and number of rois

if nargin < 2,rois_type = "neurons"; end
if nargin < 3, state = "Run"; end
if nargin < 4, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);

% Get only neurons (default)/astrocytes
if rois_type == "neurons"
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
tab(tab.category == "spikes_prob",:) = [];


% get rid of rois w/o events
% tab_both = tab(tab.events_min ~= 0,:);

for i = 1:length(rois_t)
    t = tab(tab.roi_type == rois_t(i),:);
    t = t(:,{'seg_category','roi_type','roi_short_name','exp_state','events_min'});
    
    t =  sortrows(t,{'exp_state','events_min'},'ascend');
    
    if do_save
        if  nargin == 5 && ~isempty(out_path)
            p = out_path;
        else
            p = "/Volumes/GlyR/GlyR project/Plots/Activity_summary/Unpaired";
            p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
        end
        filename = rois_type + "/tabs/events_unpaired_summary_" + ...
            state + "_" + unique(tab.exp_category) + "_" + rois_t(i) ;
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        writetable(t,filename,'FileType','spreadsheet');
    end
end

end