% Find when the laser is on to synchronyze imaging with rig and whisker data
function get_onset(trials)
disp('Extracting laser trace...')
for trial = trials
    % if trial.has_var('video_region_names') & ~trials.has_var('laser_data')
    %     disp("Reading laser roi data from " + trials.path + "...")
    %     videoroi_data = PROTOTYPING.camera_regions.read(trials); %yucca.mod.camera_regions.read(trials);
    %     laser_data = videoroi_data.laser;
    %     trials.save_var('laser_data',laser_data)
    %     disp('Laser data saved')
    % elseif trials.has_var('laser_data')
    %     disp(trials.path + " already has laser data")
    % else
    %     error(trials.path + " does not have laser roi data.")
    % end

    %% Find when the laser turns on
    %look for the laser onset in the first 2s of the recording
    if trial.has_var('laser_data')
        d = trial.load_var('laser_data');
        idx = d.Time <= 10;
        [maxi,loc] =  max(d.Data(idx));
        med = median(d.Data(idx));
        if maxi > 5*med
            laser_onset = d.Time(loc);
        else
            laser_onset = d.Time(1);
        end
        trial.save_var('laser_onset',laser_onset)
        disp('Laser onset saved')
    else
        warning(trial.path + " does not have laser data.")
    end
end
disp('Done')
end
