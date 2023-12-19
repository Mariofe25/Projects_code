function locomotion_classification =  classify_locomotion_old(trials)
% still
% 1º transition: still-running == still part
% 1º transition: still-running == running part
% running
% 2º transition: running-still == running part
% 2º transition: running_still == still part

for trial = trials
    fps = 20;
    dt = 1/fps;
    binarize_locomotion =  trial.load_var('running');
    binarize_locomotion  = binarize_locomotion.Data;
    
    % Still (still - transitions)
    %  Still periods must be longer than 5s (since the 2 first/last
    % will be consider part of the transition to/from running)
    frames_5s = 5/dt;
    still =  binarize_locomotion == 0;
    still_periods = bwconncomp(still).PixelIdxList;
    still_frames = arrayfun(@(s) length(s{:}), still_periods);
    still_sec = still_frames*dt;
    still_periods = still_periods(still_frames > frames_5s);
    
    % still transition
    trans_2s = 2/dt;
    % first 2s of the still periods
    f2s_still = cellfun(@(s) s(1:trans_2s,:),still_periods,'UniformOutput',false);
    % last 2s of the still period
    l2s_still = cellfun(@(s) s(end-trans_2s+1:end,:),still_periods,'UniformOutput',false);
    % strictly still period
    strict_still = cellfun(@(s) s(trans_2s+1:end - trans_2s),still_periods,'UniformOutput',false);
    % eliminate transitions at the start/end of the trace
    if f2s_still{1}(1) == 1
        f2s_still(1) = [];
    end
    if l2s_still{end}(end) == length(binarize_locomotion)
        l2s_still(end) = [];
    end
    
    % Running
    frames_4s = 4/dt;
    run = binarize_locomotion;
    run_periods = bwconncomp(run).PixelIdxList;
    run_frames = arrayfun(@(s) length(s{:}), run_periods);
    run_sec = run_frames*dt;
    run_periods = run_periods(run_frames > frames_4s);
    
    % running transition
    % first 2s of the run periods
    f2s_run = cellfun(@(s) s(1:trans_2s,:),run_periods,'UniformOutput',false);
    % last 2s of the run period
    l2s_run = cellfun(@(s) s(end-trans_2s+1:end,:),run_periods,'UniformOutput',false);
    % strictly run period
    strict_run = cellfun(@(s) s(trans_2s+1:end - trans_2s),run_periods,'UniformOutput',false);
    % eliminate transitions at the start/end of the trace
    if f2s_run{1}(1) == 1
        f2s_run(1) = [];
    end
    if l2s_run{end}(end) == length(binarize_locomotion)
        l2s_run(end) = [];
    end
    %   other = categorical("other");
    %   b = categorical("still_bin");
    %   loc = repmat(b,length(binarize_locomotion),1);
    %   loc(binarize_locomotion == 1) = categorical("run_bin");
    %% Strict periods
    %Still = repmat(other,length(binarize_locomotion),1);
    Still = zeros(size(binarize_locomotion));
    s = cat(1,strict_still{:});
    Still(s) = 1;
    % Still(s) = categorical("Still");
    
    %Run = repmat(other,length(binarize_locomotion),1);
    Run = zeros(size(binarize_locomotion));
    r = cat(1,strict_run{:});
    Run(r) = 1;
    %Run(r) = categorical("Run");
    
    %% 1º transition (Still-Run)
    %Transition_1 = repmat(other,length(binarize_locomotion),1);
    Transition_1 = zeros(size(binarize_locomotion));
    Transition_1_still = zeros(size(binarize_locomotion));
    Transition_1_run = zeros(size(binarize_locomotion));
    t_s = cat(1,l2s_still{:});
    t_r = cat(1,f2s_run{:});
    t = [t_s;t_r];
    %Transition_1(t) = categorical("T1");
    Transition_1(t) = 1;
    % check that the 2 parts of the transition are present (if not, remove
    % transition)
    t1 = bwconncomp(Transition_1).PixelIdxList;
    if all(cellfun(@(s) length(s),t1) == 2*trans_2s) % 80 frames
        Transition_1_still(t_s) = 1;
        Transition_1_run(t_r) = 1;
    else
        t1_idx = cellfun(@length,t1) == trans_2s;
        c = t1(t1_idx);
        c = cell2mat(c);
        mat_l2s_still = cell2mat(l2s_still);
        mat_f2s_run = cell2mat(f2s_run);
        idx_s = ~all(ismember(mat_l2s_still,c));
        %         idx_ss = find(all(ismember(mat_l2s_still,c)));
        %         if ~isempty(idx_ss)
        %             last = mat_l2s_still(idx)
        %
        %         end
        %         idx_r = find(all(ismember(mat_f2s_run,c)));
        %          if ~isempty(idx_r)
        %             first = mat_f2s_run(1,idx_r)
        %             before_first = first-1;
        %             [~,b, ~] =find(ismember(mat_l2s_still,before_first));
        %              idx_s = ;
        %
        %         end
        
        %         idx_s = ~all(ismember(mat_l2s_still,c));
        idx_r = ~all(ismember(mat_f2s_run,c));
        t_s = cat(1,l2s_still{idx_s});
        t_r = cat(1,f2s_run{idx_r});
        t = [t_s;t_r];
        Transition_1_still(t_s) = 1;
        Transition_1_run(t_r) = 1;
        Transition_1 = zeros(size(binarize_locomotion));
        Transition_1(t) = 1;
    end
    
    %% 2º transition (Run-Still)
    %Transition_2 = repmat(other,length(binarize_locomotion),1);
    Transition_2 = zeros(size(binarize_locomotion));
    Transition_2_still = zeros(size(binarize_locomotion));
    Transition_2_run = zeros(size(binarize_locomotion));
    t_s = cat(1,f2s_still{:});
    t_r = cat(1,l2s_run{:});
    t = [t_s;t_r];
    Transition_2(t) = 1;
    %Transition_2(t) = categorical("T2");
    t2 = bwconncomp(Transition_2).PixelIdxList;
    if all(cellfun(@(s) length(s),t2) == 2*trans_2s) % 80 frames
        Transition_2_still(t_s) = 1;
        Transition_2_run(t_r) = 1;
    else
        t2_idx = cellfun(@length,t2) == trans_2s;
        c = t2(t2_idx);
        c = cell2mat(c);
        mat_f2s_still = cell2mat(f2s_still);
        mat_l2s_run = cell2mat(l2s_run);
        
%         idx_s = find(all(ismember(mat_l2s_still,c)));
%         idx_r = find(all(ismember(mat_l2s_still,c)));
        idx_s = ~all(ismember(mat_f2s_still,c));
        %         if ~all(idx_s)
        
        idx_r = ~all(ismember(mat_l2s_run,c));
        t_s = cat(1,f2s_still{idx_s});
        t_r = cat(1,l2s_run{idx_r});
        t = [t_s;t_r];
        Transition_2_still(t_s) = 1;
        Transition_2_run(t_r) = 1;
        Transition_2 = zeros(size(binarize_locomotion));
        Transition_2(t) = 1;
    end
    
    %% Save binarize segments/transitions
    loc_names = {'Strict_run','Strict_still','Transition_still/run','Transition_still/run_1',...
        'Transition_still/run_2','Transition_run/still','Transition_run/still_1','Transition_run/still_2'};
    loc_vals = [Run,Still,Transition_1,Transition_1_still,Transition_1_run...
        Transition_2,Transition_2_run,Transition_2_still];
    locomotion_classification = array2table(loc_vals,'VariableNames',loc_names);
    trial.save_var('locomotion_classification',locomotion_classification)
    
end

end