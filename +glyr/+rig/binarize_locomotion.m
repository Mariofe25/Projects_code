function [locomotion,locomotion_tab] = binarize_locomotion(trials,do_transitions)
% Takes the speed trace and classifies it in different locomotion states.
% deg/s and time decides that. Categories(this can be change, tbd: as function iputs):
% still --> 0-2 deg/s
% motion --> everthing that can no be consider still, because it has higher
% deg/s, or run, because it is not fast enough or it last less than x
% seconds (3)
% running --> when it is more than 15 degs/s and it last at least 3secs
% transitions from still to run and vicerversa

if nargin < 2, do_transitions = true; end
import begonia.logging.log
%% Set Parameters
fps = 20; % Hz rotatory encoder
dt = 1/fps;
min_duration_s = 3; % minimun sec running period
run_dg = 15; % min deg/s to be considered running
still_dg = 2;% give some margin
transition_dur = 1; % 20 frames

%% Classify locomotion
r = 0;
for trial = trials
    log(1,'Classifing locomotion states from %s...', trial.path)
    r = r + 1;
    speed = trial.load_var('speed');
    speed_dsec = speed.Data;
    
    %% Strict still
    log(1,'Getting locomotion states: still, motion and running')
    % Values < 2 & > 0
    still_segments = round(speed_dsec) <= still_dg & round(speed_dsec) >= -1;
    still_segments = bwconncomp(still_segments).PixelIdxList;
    
    % No less than 2 sec
    still_dur = 2/dt;
    s_lengths = arrayfun(@(s) length(s{:}), still_segments);
    still_segments = still_segments(s_lengths > still_dur);
    
    still_idx = vertcat(still_segments{:});
    strict_still = false(length(speed_dsec),1);
    strict_still(still_idx) = 1;
    
    %% Motion & Running
    % Motion
    motion = ~strict_still;
    motion_segments = bwconncomp(motion).PixelIdxList;
    
    % Remove motion segments that are too short (0.5 secs)
    no_motion = cellfun(@length,motion_segments) < 10;
    
    if any(no_motion)
        to_remove = vertcat(motion_segments{no_motion});
        motion(to_remove) = 0;
        motion_segments = motion_segments(~no_motion);
        
        % Update strict still with the removed motion indices
        strict_still = ~motion;
        still_segments = bwconncomp(strict_still).PixelIdxList;
    end
    
    % Running
    run_segments = speed_dsec > run_dg;
    run_segments = bwconncomp(run_segments).PixelIdxList;
    
    % Running.rule 2 - segments must be no less than 3 seconds:
    run_s = min_duration_s/dt;
    run_lengths = arrayfun(@(s) length(s{:}), run_segments);
    run_segments = run_segments(run_lengths > run_s);
    
    run_idx = vertcat(run_segments{:});
    strict_run = false(length(speed_dsec),1);
    strict_run(run_idx) = 1;
    
    %% Transitions
    if do_transitions
        log(1,'Getting %ds transitions',transition_dur)
        trans_s = transition_dur/dt;
        
        % consider only motion segments that last more than 2 sec (40 frames)
        nope_idx = cellfun(@length,motion_segments) < 2*trans_s;
        motion_segments = motion_segments(~nope_idx);
        
        % still-motion transition
        last_s =  cellfun(@(s) s(end-trans_s+1:end,:),still_segments,'UniformOutput',false);
        first_r =  cellfun(@(s) s(1:trans_s,:),motion_segments,'UniformOutput',false);
        
        % eliminate transitions at the start/end of the trace
        if ~isempty(first_r) && first_r{1}(1) == 1
            first_r(1) = [];
        end
        if ~isempty(last_s) && last_s{end}(end) == length(speed_dsec)
            last_s(end) = [];
        end
        
        trans_still_motion = false(length(speed_dsec),1);
        trans_still_motion([vertcat(last_s{:});vertcat(first_r{:})]) = 1;
        
        % motion-still transition
        last_r =  cellfun(@(s) s(end-trans_s+1:end,:),motion_segments,'UniformOutput',false);
        first_s =  cellfun(@(s) s(1:trans_s,:),still_segments,'UniformOutput',false);
        
        % eliminate transitions at the start/end of the trace
        if ~isempty(first_s) && first_s{1}(1) == 1
            first_s(1) = [];
        end
        if ~isempty(last_r) && last_r{end}(end) == length(speed_dsec)
            last_r(end) = [];
        end
        
        trans_motion_still = false(length(speed_dsec),1);
        trans_motion_still([vertcat(first_s{:});vertcat(last_r{:})]) = 1;
        
        % Clean up short transitions.
        % Transitions must be 1sec in each direction (still & motion).
        % Eliminate the ones that are not in both
        transsm_segs = bwconncomp(trans_still_motion).PixelIdxList;
        transms_segs = bwconncomp(trans_motion_still).PixelIdxList;
        
        t1_idx = cellfun(@length,transsm_segs) < 2*trans_s;
        t2_idx = cellfun(@length,transms_segs) < 2*trans_s;
        
        trans_still_motion(vertcat(transsm_segs{t1_idx})) = 0;
        trans_motion_still(vertcat(transms_segs{t2_idx})) = 0;
    end
    
    %% Make table w/ binarize states & vector w/ behav.states categories
    % Transitions are assigned in the end so that the trace's still/motion/
    % run indices are overwritten with the trans category
    log(1,'Assigning locomotion category to binarized traces')
    if do_transitions
        cats = ["Still","Motion","Run","Transition_still_motion","Transition_motion_still"];
    else
        cats = ["Still","Motion","Run"];
    end
    
    %     binarized_state = [strict_still,motion,strict_run,trans_still_motion,trans_motion_still];
    %     binarized_state = array2table(binarized_state,'VariableNames',cats);
    
    % Locomotion vector to segment multitab
    locomotion = repmat(categorical(""),length(speed_dsec),1);
    locomotion(strict_still) = cats(1);
    locomotion(motion) = cats(2);
    locomotion(strict_run) = cats(3);
    if do_transitions
        locomotion(trans_still_motion) = cats(4);
        locomotion(trans_motion_still) = cats(5);
    end
    
    % locomotion table that specifies the start/end time of each state
    loc_type = double(locomotion);
    loc_change = find(ischange(loc_type));
    
    locomotion_state = [locomotion(1);locomotion(loc_change)];
    start_frame = [1;loc_change];
    end_frame = [loc_change - 1;length(locomotion)];
    deltat = repmat(dt,numel(locomotion_state),1);
    start_sec = (start_frame * dt) - dt;
    end_sec = (end_frame * dt) - dt;
    sec_duration = end_sec - start_sec;
    
    locomotion_tab = table(locomotion_state,start_frame,end_frame,deltat,...
        start_sec,end_sec,sec_duration);
    
    % Save table and categorical vector
    trial.save_var('locomotion_tab',locomotion_tab)
    trial.save_var('locomotion')
end
log(1,'Done!')
end