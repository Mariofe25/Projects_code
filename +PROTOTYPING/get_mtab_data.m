%% find trials with rois and rig traces (data = mtable)

function  [trials, trial_name] = get_mtab_data(gdata,timeStep)

if nargin == 1
  timeStep = 1/30;  
end
% read data groups from mta
trials_groups = unique(gdata.mtab.tab.group_id);
disp(numel(trials_groups) + " trials found in mtab. Filtering...")
% take the groups_id with roi, wheel, whisker(s) and pupil tracesr.d,vxz ec
trials = cell(1,length(trials_groups));
row = 1;
for i = 1:length(trials_groups)   
    trial_id = string(trials_groups(i));
    disp("Getting trial traces from " + trial_id)
    trial = gdata.mtab.by_group_and_cat(trial_id, ["roitrace","wheel","pupil","whisker"], timeStep, "trim");
    
    % Check trial has all traces types
    roi = any(ismember(trial.category, "roitrace"));
    wheel = any(ismember(trial.category, "wheel"));
    pupil = any(ismember(trial.category, "pupil"));
    whisker = any(ismember(trial.category, "whisker"));  %whisk_logs and whisking
    traces = [roi,wheel,pupil,whisker];
    traces_names = {'roi','wheel','pupil','whisker'};
    
    if all(traces)%roi && wheel && pupil
        % make some tags columns to ease access later
        disp('Getting trial tags..')
        trial = gdata.mtab.tag_to_column (trial, "roi_channel", @categorical);
        trial = gdata.mtab.tag_to_column(trial, "roi_group", @categorical);
        trial = gdata.mtab.tag_to_column(trial, "mouse", @categorical);
        trial = gdata.mtab.tag_to_column(trial, "state", @string);
        trials{row} = trial;
        trial_name{row} = trial_id;
    else
        traces_names = traces_names(~traces);
        if numel(traces_names) == 1
            disp(trial_id + " lacks  " + traces_names + " trace")
        elseif numel(traces_names) == 2
            disp(trial_id + " lacks  " + traces_names{1} + " & " + traces_names{2} + " traces")
        elseif numel(traces_names) == 2
             disp(trial_id + " lacks  " + traces_names{1} + " & " + traces_names{2} + " traces" + traces_names{3} + " traces")
        else
            disp(trial_id + " does not have traces. WHY IS IT ON MTAB??. Skipping")
        end
        continue
    end
    disp("Done")
    row = row + 1;
end
trials(cellfun(@isempty,trials)) = [];
disp(numel(trials) + "/" + numel(trials_groups) + " selected")
end