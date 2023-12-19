function calculate_speed(mtab,dat)
    for i = 1:length(dat)
    dt = 1/10;
    %row = asdata.megatable.by_group_and_cat(ts_name, "wheel.deltaangle", dt, "trim");
    da = dat{i}.trace(dat{i}.category == "wheel");
     % resample to 30fps for simplicity

    trace_da = da{:};
    % invert direction (negative is forward)
    
    % traces is in degrees/sample, and sample rate is 20 pr. second
    % we want degrees/sec, so we can multiply by 20 to get speed 
    % = degrees/sec
    % (the data was resampled to 30 fps on import in add_wheel)
    trace_da = trace_da * 10;
    
    % smooth the speed by taking the movesum for 45 frames (1.5 sec)
    trace_speed = movmean(trace_da, 15); 
    
    % speed can be negative, but we can get a metric for all motion
    % by taking the absolute value
    trace_abs_mov = movsum(abs(trace_da), 30);  
    
    %trace_speed_old = movsum(trace_da, 45);  
    %trace_abs_mov_old = movsum(abs(trace_da), 30);  
    trace = trace_speed;
    
    dt = unique(dat{i}.delta_time);
    group_id = unique(dat{i}.group_id);
    data_id = "speed-" + string(group_id);
    category = "speed";
   
    mtab.update(trace,data_id, group_id, category,"", "degrees/s", dt);
    mtab.save()
    end
    %mtab.update(trace_speed, ts_name + "-speed", ts_name, "speed", tags, "degrees/sec", dt);
    %mtab.update(trace_abs_mov, ts_name + "-abs_movement", ts_name, "abs_movement", tags, "degrees/sec", dt);
end
