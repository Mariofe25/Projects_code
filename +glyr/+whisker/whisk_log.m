function whisk_log = whisk_log(trials)
import begonia.logging.log;
% It takes the times registered in trial.Logs to know when the wall is
% out/in. Time differs among tseries beacuse extension lenght of the pole
% is not alwasy the same.
% Saves the result as a timetable(30fps) on trial.metadata.

for trial = trials
    log(1, "Getting whisker time info: " + trial.name)
    % Get logs from trial
    Log = trial.Log;
    
    % Get laser onset to sync w/ start image recording
    laser_onset = trial.load_var('laser_onset');
    
    % Convert datetime to seconds
    [~, ~, ~, H, MN, S] = datevec(Log.Time);
    ti = H*3600+MN*60+S;
    Time = ti - ti(1);
    Time = seconds(Time);
    
    %% Identify when the wall is out/in
    wall  = zeros(length(Time),1);
    
    % Start stimulation period (linear motor motion start)
    st_idx = find(Log.Message == "P2",1,"last");
    
    % Estimated touching (linear motor stops)
    pole_out = Log.Message == "Pole out";
    
    % End of stimulation
    pole_in = find(Log.Code == "Whisker stim",1,"last");
    %%
    % Create timetable
    w_stim = timetable(Time,wall);
    
    % Weird. Events sometimes are not registered in order and need to
    % be sorted(|-_-|)
    w_stim = sortrows(w_stim,'Time');
    
    % Resample to 30fps
    w_stim = retime(w_stim,"regular","previous","TimeStep",seconds(1/30));
    
    % Sync w/ image recording
    rem = seconds(w_stim.Time) <= laser_onset;
    w_stim(rem,:) = [];
    w_stim.Time = w_stim.Time - w_stim.Time(1);
    
    % Result
    whisk_log = struct();
    whisk_log.start = Time(st_idx) - seconds(laser_onset);
    whisk_log.estimated_start = Time(pole_out) - seconds(laser_onset);
    whisk_log.stop = Time(pole_in) - seconds(laser_onset);
    st = w_stim.Time >= whisk_log.start;
    sp = w_stim.Time <= whisk_log.stop;
    w_stim.wall(st & sp) = 1;
    whisk_log.trace = w_stim;
    
    trace = repmat(categorical(""),height(w_stim),1);
    trace(1:find(w_stim.wall,1,"first")-1) = "Baseline";
    trace(w_stim.wall == 1) = "Stim";
    trace(find(w_stim.wall,1,"last")+1:end) = "Post";
     
    % Save it
    trial.save_var('trace_cat',trace)
    trial.save_var('whisker_log',whisk_log)
end
end