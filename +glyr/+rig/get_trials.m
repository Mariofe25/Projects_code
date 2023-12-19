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