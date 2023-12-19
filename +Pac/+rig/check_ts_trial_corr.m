function corr_tab = check_ts_trial_corr(tss,trials, margin)
% check that the correlation tseries-trial seems legit

if nargin < 3, margin = seconds(30); end

if ~isduration(margin), margin = seconds(margin); end

tss_id = string({tss.name})';

tss_start = [tss.start_time_abs]';
trials_start = [trials.start_time_abs]';

tss_duration = seconds([tss.duration])';
trials_duration = seconds([trials.duration])';

diff_start = tss_start - trials_start;
diff_duration = tss_duration - trials_duration;

corr_tab = table(tss_id,tss_start,trials_start,diff_start,tss_duration,...
    trials_duration,diff_duration);

check_idx = find(abs(diff_start) > margin);
if ~any(check_idx)
    disp("All TSeries and correalted Trials seem to start about the same time")
else
    disp("Some TSereis-Trials correlation seems a bit off. Check it")
end

check_idx = find(abs(diff_duration) > margin);
if ~any(check_idx)
    disp("All TSeries and correalted Trials seem to last the same time")
else
    disp("Some TSereis-Trials correlation have different duration. Check it")
end
