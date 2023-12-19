function [speed,m] = get_speed(trials)
import begonia.logging.backwrite 
n = 0;
m = [];
fprintf('\n')
for trial = trials
    n = n + 1;
    msg = sprintf('Calculating speed in cm/s for trials %d of %d', n, length(trials));
    backwrite(1,msg)
    %row = asdata.megatable.by_group_and_cat(ts_name, "wheel.deltaangle", dt, "trim");
    da = trial.load_var('wheel_trim');
    
    % Check that the recording was stable
    ti = da.Time;
    tdrop = sum(abs(diff(ti,2)));
    if tdrop >= 0.2 % drop 0.2 secs
        warning("Check trial " + n + " from the Trials list variable. Recording" + ...
            " not stable")
        m = [m,n];
    end
    
    % invert direction (negative is forward)
    trace_da = da.Data*-1;

    % traces is in degrees/sample, and sample rate is 20 pr. second
    % we want degrees/sec, so we can multiply by 20 to get speed
    % = degrees/sec

    trace_da = trace_da * 20;

    % smooth the speed by taking the movesum for 20 frames (1 sec)
    trace_speed = movmean(trace_da, 20);

    % transform to cm/s
    % radious running wheel in cm;

    % Convert speed trace to cm/s (v = r*w)(w in rad/s)
    r = 0.08; % 8 cm (in m)
    conv_rad = pi/180;
    trace_speed = r * conv_rad * trace_speed *100; %cm/s

    % update timeseries
    speed = da;
    speed.Data = trace_speed;

    speed.Name = 'cm/s';

    % speed can be negative, but we can get a metric for all motion
    % by taking the absolute value
    %     trace_abs_mov = movsum(abs(trace_da), 30);

    %trace_speed_old = movsum(trace_da, 45);
    %trace_abs_mov_old = movsum(abs(trace_da), 30);
    trial.save_var('speed',speed)
end
end
