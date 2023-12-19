function [pupil_trim, pupil_data] = trim_pups(trials)
import begonia.logging.log
%% Trim pupil data
log(1,'Trimming pupil data...')
for trial = trials
    if trial.has_var('laser_onset')
        laser_onset = trial.load_var('laser_onset');
    else
        log(1,trial.path + " does not have 'laser_onset' variable")
        continue
    end
    
    if ~trial.has_var('pupil_diameter')
        warning(trial.path + " does not have pupil data. Skipping")
        continue
    else
        pupil_data = trial.load_var('pupil_diameter');
        rate_data = trial.load_var('pupil-eye_ratio');
    end
    
    % trim
    pupil_trim = trim_it(pupil_data,laser_onset);
    pupil_rate_trim = trim_it(rate_data,laser_onset);
    
    %save
    trial.save_var('pupil_trim',pupil_trim)
    trial.save_var('pupil-rate_trim',pupil_rate_trim)
end
log(1,"Done!")
end

function trim = trim_it(data,laser_onset)
trim = delsample(data,"Index", find(data.Time < laser_onset));
% Correct the time shift
trim.Time = trim.Time - trim.Time(1);
end