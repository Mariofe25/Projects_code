function [event_onset,event_onset_ratios,event_onset_simp,...
    event_on_ratios_simp,n_trans,total_rois] = evs_onset_loc(tss,exp_state,...
    loc_length,do_simplify,do_save)
% Find the first event onset after a transition from still to locomotion

if nargin < 5, do_save = false; end
if nargin < 4, do_simplify = true; end
if nargin < 3, loc_length = 5; end % minimum after segment length
if nargin < 2, exp_state = "Stimulation"; end

% get transtions tabs
virus = unique(string(tss.load_var('virus')));
drug = string(unique(tss.load_var('drug')));
fs = 30;
n = 0;
for ts = tss
    n = n +1;
    if ts.has_var("transtab_" + exp_state + "_pup")
        tab{n} = ts.load_var("transtab_" + exp_state + "_pup");
    else
        tab{n} = {};
    end
end
tab(cellfun(@isempty,tab)) = [];
tab = vertcat(tab{:});

% Filter table by length of run/motion part (trans_end - trans_start)
tab.trans_length =  cellfun(@length,tab.trans_idx);
if loc_length > 0
    filt_loc = 3*fs + fs*loc_length;
%     tab(tab.trans_length < (filt_loc - 15) | tab.trans_length > (filt_loc + 15),:) = [];
tab(tab.trans_length < (filt_loc - 15),:) = [];
end

rois_types = unique(tab.roi_type);
rois_types(ismissing(rois_types)) = [];

% Number of transitions 
total_trans = numel(unique(tab.trans_id));

% Number of each roi type 
n_rois = glyr.get_nrois(tab);
n_rois = n_rois.values;
total_rois = [n_rois{:}];

% Number of transitions with events
tab(tab.total_events == 0,:) = [];

% Number of active rois
n_rois = glyr.get_nrois(tab);
n_rois = n_rois.values;
active_rois = [n_rois{:}];

active_prctg = active_rois./total_rois;

% get max length transition
lngst = ceil((max(tab.trans_length) - 3*fs)/fs);
if loc_length > 0
    times = (-3.25:0.25:loc_length)'*30;
else
    times = (-3.25:0.25:lngst)'*30;
end
times(times == 0) = [];

for i = 1:numel(rois_types)
    rois = tab(tab.roi_type == rois_types(i),:);
    rois(rois.seg_category == "spikes_prob",:) = [];

    % Find the events. Onset is ftom end of transition (aka -1 =
    % transition)
    evs = cellfun(@find,rois.events,'UniformOutput',false);

    % Get frame onset of events. Take the onset from the transition start
    %     ee = arrayfun(@(s,f,e) s{:} - (f - e), evs,rois.trans_start,...
    %         rois.trans_start_idx,"UniformOutput",false);
    fs = 30;
    ee = cellfun(@(s) s - 3*fs,evs,'UniformOutput',false); % 3 --> 2s before seg + 1s transition

    % take only the first event and get rid of rois w/o events
    ee(cellfun(@isempty,ee)) = [];
    es = cellfun(@(s) s(1),ee);

    % Eliminate events that occur after the minimun after segment length
    es(es > fs*loc_length) = [];

    % find the event onset
    rt = abs(es)' - times;
    [~,midx] = min(abs(rt));
    ac = times(midx)';
    ac = ac'/30;
    ac(es < 0) = ac(es < 0)*-1; % events with onset before transition
    ac(es < -3*30) = -3.25; % this will be later transform to ≤3 secs
    [r{i},~,ridx] = unique(ac);
    evs_on{i} = accumarray(ridx,1);
end

% Assign found events onsets to the right interval times
evss = zeros(length(times),numel(rois_types));
times = times/30;
evs_ons_idx = cellfun(@(s) ismember(times,s),r,"UniformOutput",false);
ee  = vertcat(evs_ons_idx{:});
evs_on = vertcat(evs_on{:});
evss = evss(:);
evss(ee) = evs_on;
evss = reshape(evss,length(times),numel(rois_types));

% Create a table
event_onset = array2table([times,evss],'VariableNames',["Time",rois_types']);
event_onset.Time = categorical(event_onset.Time);
if loc_length > 0
    event_onset.Time(1) = "<3";
    event_onset.Time(end) = "≥" + loc_length;
else
    event_onset.Time(1) = "<3";
    event_onset.Time(end) = "≥7";
end

% table ratios
evs_r = evss./sum(evss);
event_onset_ratios = array2table([times,evs_r],...
    "VariableNames", ["Time",rois_types']);
event_onset_ratios.Time = categorical(event_onset_ratios.Time);
if loc_length > 0
    event_onset_ratios.Time(1) = "<3";
    event_onset_ratios.Time(end) = "≥" + loc_length;
else
    event_onset_ratios.Time(1) = "<3";
    event_onset_ratios.Time(end) = "≥7";
end

% bin event onsets in broader time intervals
if do_simplify
    tim = [times(1);ceil(times(2:4:end))];
    tim = nonzeros(tim);

    for j = 1:size(event_onset,2)-1
        simps = sum(reshape(event_onset{2:end,j+1},4,(length(times) - 1)/4))';
        %         simps(1) = simps(1) + event_onset{2,j+1};
        simp(:,j) = [event_onset{1,j+1};simps];
    end

    event_onset_simp = array2table([tim,simp],'VariableNames',...
        ["Time",rois_types']);
    event_onset_simp.Time = categorical(event_onset_simp.Time);
    if loc_length > 0
        event_onset_simp.Time(1) = "<3";
        event_onset_simp.Time(end) = "≥" + loc_length;
    else
        event_onset_simp.Time(1) = "<3";
        event_onset_simp.Time(end) = "≥7";
    end

    % ratios
    evs_onset_ratios = simp./sum(simp);
    event_on_ratios_simp = array2table([tim,evs_onset_ratios],'VariableNames',...
        ["Time",rois_types']);
    event_on_ratios_simp.Time = categorical(event_on_ratios_simp.Time);
    if loc_length > 0
        event_on_ratios_simp.Time(1) = "<3";
        event_on_ratios_simp.Time(end) = "≥" + loc_length;
    else
        event_on_ratios_simp.Time(1) = "<3";
        event_on_ratios_simp.Time(end) = "≥7";
    end

end

% Save tables
if do_save
    path = "/Volumes/GlyR/GlyR project/Plots/Events_trans2loc/" + loc_length + "sec";
    folderpath = fullfile(path,virus,drug);
    n_ev = "Events_onset_" + exp_state;
    file_1 = fullfile(folderpath,n_ev);
    begonia.path.make_dirs(file_1)
    writetable(event_onset,file_1,'FileType','spreadsheet')
    n_rate = "Events_onset_rate_" + exp_state;
    file_2 = fullfile(folderpath,n_rate);
    begonia.path.make_dirs(file_2)
    writetable(event_onset_ratios,file_2,'FileType','spreadsheet')
    if do_simplify
        n_simp = "Events_onset_simp_" + exp_state;
        file_3 = fullfile(folderpath,n_simp);
        begonia.path.make_dirs(file_3)
        writetable(event_onset_simp,file_3,'FileType','spreadsheet')
        n_simp_rat = "Events_onset_rate_simp_" + exp_state;
        file_4 = fullfile(folderpath,n_simp_rat);
        begonia.path.make_dirs(file_4);
        writetable(event_on_ratios_simp,file_4,'FileType','spreadsheet')
    end
end
end