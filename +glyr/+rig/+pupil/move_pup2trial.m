function move_pup2trial(trials,pupil_folder,filtered)
% move pupil tracked csv file to the cosrresponding trial metadata
if nargin < 3, filtered = 1; end
if nargin < 2, pupil_folder = '/Volumes/GlyR/pupil'; end

import begonia.logging.log

% csv files paths
if filtered, ff = '*filtered.csv'; else, ff = '*0.csv';end
pup_tab_paths = dir(fullfile(pupil_folder,ff));

pup_tab_name = {pup_tab_paths.name}';
pup_path = string(fullfile({pup_tab_paths.folder},{pup_tab_paths.name}))';

%  Select part of the pupil path name include in the trial path
n_idx = (strfind(pup_tab_name,"_pupil_video"));
n_idx = [n_idx{:}]';
pup_name = cell(length(pup_tab_name),1);
for i = 1:length(pup_tab_name)
    pup_name{i} = pup_tab_name{i}(1:n_idx(i)-1);
end
% pup_name = cellfun(@(s) s(1:n_idx -1),pup_tab_name,"UniformOutput",false);

% modify pupil path name ('_' --> '/')
pup_name = string(pup_name);
idx = strfind(pup_name,"trial");
for i = 1:length(pup_name)
    pup_name{i}(idx{i}-1) = '/';
end

% trials paths
trial_path = string({trials.path})';

% Corresponding trial idx
pup_trial_idx = arrayfun(@(s) find(contains(trial_path,s)),pup_name,...
    "UniformOutput",false);
% In case there is a mistmatch (i.e.,more files in the pupil path)
rmv_idx = cellfun(@isempty,pup_trial_idx);
pup_trial_idx(rmv_idx) = [];
pup_path(rmv_idx) = [];
pup_name(rmv_idx) = [];
pup_trial_idx = [pup_trial_idx{:}]';

% check that the association is unique
un_idx = numel(unique(pup_trial_idx));
if un_idx < numel(pup_trial_idx)
    warning('Different pupil tabs are associated with the same trial! check it')
end
log(1,'Found %d/%d corresponding trials',un_idx,numel(pup_trial_idx))
log(1,'Transferrig pupil tabs to trials...')

% save table to trial metadata. Also copy the name of csv file 
for i  = 1:length(pup_path)
    tab = readtable(pup_path(i),"NumHeaderLines",2);
    trials(pup_trial_idx(i)).save_var("pupil_tab",tab)
    trials(pup_trial_idx(i)).save_var("pupil_tab_id",pup_name(i))
    trials(i).save_var("pupil_tab_filt",filtered)
end
log(1,"Transfer done!")
end