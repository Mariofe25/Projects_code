function speed = get_speed(trials)
import begonia.logging.*

n = 0;
for trial = trials 
    n = n + 1;
    s = sprintf('Calculating mouse speed in deg/s: %d/%d',n,length(trials));
    backwrite(1,s)
    da = trial.load_var('wheel_trim');
    % resample to 30fps for simplicity
    
    trace_da = da.Data*-1;
    % invert direction (negative is forward)
    
    % traces is in degrees/sample, and sample rate is 20 pr. second
    % we want degrees/sec, so we can multiply by 20 to get speed
    % = degrees/sec
    
    trace_da = trace_da * 20;
    
    % smooth the speed by taking the movesum for 30 frames (1.5 sec)
    trace_speed = movmean(trace_da, 30);
    
    speed = da;
    speed.Data = trace_speed;
    
    speed.Name = 'Deg/s';
    
    % speed can be negative, but we can get a metric for all motion
    % by taking the absolute value
    %     trace_abs_mov = movsum(abs(trace_da), 30);
    
    %trace_speed_old = movsum(trace_da, 45);
    %trace_abs_mov_old = movsum(abs(trace_da), 30);
    trial.save_var('speed',speed)
    
end
log(1,"Done!")
end
