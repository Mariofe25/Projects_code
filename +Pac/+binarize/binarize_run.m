function running = binarize_run(trials)
%{
    We need a new and stricter category of "run". We will define a run by this
    struct definition as contunous movement > n degrees/sec with a peak of at
    least m degrees pr. second , and the run lasting
    at least c seconds total
%}
%% config
MIN_DUR_S = 2;
MIN_CONT_SPEED_DS = 40/2;

% % categorize:
% CAT_RUN = categorical("run.strict");
% CAT_OTHER = categorical("other");

% speed traces are stored at 20 fps, and delta angle pr. second:
r = 0;
for trial = trials
    r = r + 1;
    fps = 20;
    dt = 1/fps;
    speed = trial.load_var('speed');
    speed_dsec = speed.Data;
    
    % rule 1 - has to be > degrees sec and continous:
    cont_segments = speed_dsec > MIN_CONT_SPEED_DS;
    cont_segments = bwconncomp(cont_segments).PixelIdxList;    
    
    % rule 2 - segments must be no less than 2 seconds:
    frames_2s = MIN_DUR_S/dt;
    seg_lengths = arrayfun(@(s) length(s{:}), cont_segments);
    cont_segments = cont_segments(seg_lengths > frames_2s);    
    
    % categorize 
    run_trace = zeros(length(speed_dsec), 1);
    for j = 1:length(cont_segments)
        seg = cont_segments(j);
        seg = seg{:};
        run_trace(seg(1):seg(end)) = 1;
    end
    
    still = run_trace == 0;
    still = bwconncomp(still).PixelIdxList;
    % duration between runs (< 500 ms) are count as part of the runs
    frames_500ms = 0.5/dt;
    still_lengths = arrayfun(@(s) length(s{:}), still);
    still = still(still_lengths < frames_500ms);
    for j = 1:length(still)
        seg = still(j);
        seg = seg{:};
        run_trace(seg(1):seg(end)) = 1;
    end
    
    % speed is not constant. Bin close runs when the mouse is not still (10
    % deg/s at least for 1 sec)
    mov = run_trace == 0;
    d = speed_dsec >= 10;
    mov = mov & d;
    mov = bwconncomp(mov).PixelIdxList;
    mov_lengths = arrayfun(@(s) length(s{:}), mov);
    mov = mov(mov_lengths < 10);
    mov = cat(1,mov{:});
    run_trace(mov) = 1;
    
    r = bwconncomp(run_trace).PixelIdxList;
    r_lengths = arrayfun(@(s) length(s{:}), r);
    r = r(r_lengths < 20);
    r = cat(1,r{:});
    run_trace(r) = 0;
    
    rr = run_trace == 0;
    rr = bwconncomp(rr).PixelIdxList;
    rr_lengths = arrayfun(@(s) length(s{:}), rr);
    rr = rr(rr_lengths < 5);
    rr = cat(1,rr{:});
    run_trace(rr) = 1;
    
    running = speed;
    running.Data = logical(run_trace);
    running.Name = 'binarize run';
    
    trial.save_var('running',running)     
end
end