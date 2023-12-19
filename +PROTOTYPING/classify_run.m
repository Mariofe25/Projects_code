function classify_strict_run(mtab,data)
    %{
    We need a new and stricter category of "run". We will define a run by this
    struct definition as contunous movement > n degrees/sec with a peak of at
    least m degrees pr. second , and the run lasting
    at least c seconds total
    %}
    %% config
    MIN_DUR_S = 5;
    PRE_INCLUDE_S = 1;
    MIN_CONT_SPEED_DS = 40/2;
    MAX_PRE_SPEED_DS = 20/2;
    PRESEG_START_S = -12;
    PRESEG_END_S = -2;
    
    
    % categorize:
    CAT_RUN = categorical("run.strict");
    CAT_OTHER = categorical("other");

    % speed traces are stored at 20 fps, and delta angle pr. second:
    for i = 1:length(data)
    fps = 10;
    dt = 1/fps;
    speed_dsec = data{i}.trace(data{i}.category == "speed");
    speed_dsec = speed_dsec{:};


    % rule 1 - has to be > degrees sec and continous:
    cont_segments = speed_dsec > MIN_CONT_SPEED_DS;
    cont_segments = bwconncomp(cont_segments).PixelIdxList;

    % add 2 seconds before segments:
    for j = 1:length(cont_segments)
        seg = cont_segments(j);
        seg = seg{:};
        pre_seg = (seg(1) - (PRE_INCLUDE_S/dt)):(seg(1)-1);
        cont_segments(j) = {[pre_seg'; seg]};
    end

    % rule 2 - segments must be no less than 5 seconds:
    frames_4s = MIN_DUR_S/dt;
    seg_lengths = arrayfun(@(s) length(s{:}), cont_segments);
    cont_segments = cont_segments(seg_lengths > frames_4s);

    % rule 3 : segment cannot have had any speed > MIN_CONT_SPEED the 12:2
    % seconds before:
    valid = logical.empty;
    for j = 1:length(cont_segments)
        valid(j) = false;

        seg = cont_segments(j);
        seg = seg{:};

        preseg_start = seg(1) + (PRESEG_START_S/dt);
        preseg_end = seg(1) + (PRESEG_END_S/dt);
        if preseg_start < 1
            break;
        end

        pretrace = speed_dsec(preseg_start:preseg_end); 
        valid(j) = max(pretrace) < MAX_PRE_SPEED_DS;
    end

    cont_segments = cont_segments(valid);


    % categorize and commit to megatable:
    run_trace = repmat(CAT_OTHER, length(speed_dsec), 1);
    for j = 1:length(cont_segments)
        seg = cont_segments(j);
        seg = seg{:};

        run_trace(seg(1):seg(end)) = CAT_RUN;
    end

    ts.save_var("bh_run", run_trace)
        
    disp(ts.name + " - classified strict run, got " + length(cont_segments) + " segments");
    end
end