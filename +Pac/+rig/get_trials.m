function [trial,tss_no_trials] = get_trials(tss)
tss_no_trials = [];
for i = 1:length(tss)
    try
        trial_path = tss(i).load_var("associated_trial");
        trial{i} = yucca.trial.Trial(trial_path);
    catch
        trial{i} = [];
        warning(tss(i).name + ": no associated trial found")
        tss_no_trials = [tss_no_trials;tss(i)];
        continue
    end
end
end

% function trials =  get_trials(tss,t)
% if nargin < 2
%     try
%         trials_path = '/Volumes/Xiaoyi1/PAC/wheel data';
%         t = yucca.trial_search.find_trials(trials_path);
%     catch
%         trials_path = uigetdir;
%         t = yucca.trial_search.find_trials(trials_path);
%     end
% end
% trials = yucca.util.correlate_ts_trial(tss,t);
% trials = trials.values;
% trials = [trials{:}];
% end
