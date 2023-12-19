% Trim the wheel data at the laser onset
function [whisk_trim,whisking] = trim_whisking(trials)

for trial = trials
    vid_rois = PROTOTYPING.camera_regions.read(trial);
    whisking = vid_rois.whisker;
    if trial.has_var('laser_onset')
        laser_onset = trial.load_var('laser_onset');
    else
        disp(trial.path + "does not have laser_onset var")
        continue
    end    
    
    % indices lower than laser onset
    idx_trim = find(whisking.Time < laser_onset);
    % trim tscollecion
    whisk_trim = delsample(whisking,'index', idx_trim);
    % Correction time shift
    dt = whisking.Time(2) - whisking.Time(1);
    whisk_trim.Time = whisk_trim.Time - numel(idx_trim)*dt;
    if whisk_trim.TimeInfo.Start ~= 0
        whisk_trim.Time = whisk_trim.Time -  whisk_trim.Time(1);
    end
    
    trial.save_var('whisking',whisking)
    trial.save_var('whisking_trim',whisk_trim)
    disp("Whisking saved")
    
end