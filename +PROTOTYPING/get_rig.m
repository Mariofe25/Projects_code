function [trials,tss_with_trials,tss_no_trials,tss_path_list] = get_rig(gdata,tss)

if nargin <= 1
    error('Input should look like this --> get_laser_onset(gdata,tss)')
end
%% List trials
id = 1;
disp('Looking for rig data')
for ts = tss
    tsi = gdata.dcat.get_info(ts.dl_unique_id);
    rig = tsi.overlaping_in_time({tsi.overlaping_in_time.type} == "Recording rig output");
    try
        trials(id) = gdata.dcat.get_data(rig);
        disp(ts.name + " Rig data found")
        id = id + 1;
    catch err
        warning(ts.name + ". " + err.message + " Skipping");
        continue;
    end
end

disp(length(trials) + " trials found")
tss_valid = yucca.trial.correlate_stacks_alt(tss,trials);
tss_with_trials = tss_valid;
tss_no_idx = ismember(tss,tss_valid);
tss_no_trials = tss(~tss_no_idx);
tss_ok = {tss_valid.path}';
tss_ko = {tss_no_trials.path}';

if length(tss_ok) > length(tss_ko)
    s = length(tss_ok) - length(tss_ko);
    tss_ko = vertcat(tss_ko, cell(s,1));
else
    s = length(tss_ko) - length(tss_ok);
    tss_ok = vertcat(tss_ok, cell(s,1));
end

tss_path_list = table(tss_ok,tss_ko,'VariableNames',{'Tseries with rig data','Tseries w/o rig data'});

end