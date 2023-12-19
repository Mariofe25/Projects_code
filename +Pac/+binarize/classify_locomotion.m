function locomotion_classification =  classify_locomotion(trials,still_sec,run_sec,transition_sec)

% inputs: trials = trial object
%         still_sec = min seconds to consider a segment as "still"
%         run_sec =  min seconds to consider a segment as "run"
%         transition_sec = transition duration in seconds

% f.e --> locomotion_classification =  classify_locomotion(trials,5,4,2)

if nargin < 2
    still_sec = 5;
    run_sec = 4;
    transition_sec = 2;    
end

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
    binarize_locomotion = binarize_locomotion.Data;
    size_bin_loc = zeros(size(binarize_locomotion));
    
    %% Segments
    % Still segs
    still =  binarize_locomotion == 0;
    still_duration = still_sec/dt;
    [f2s_still,strict_still,l2s_still] = segmentation_state(still,still_duration,transition_sec,dt);
    
    % Running segs
    run_duration = run_sec/dt;
    [f2s_run,strict_run,l2s_run] = segmentation_state(binarize_locomotion,run_duration,transition_sec,dt);
    
    %% Strict periods
    Still =  size_bin_loc;
    s = cat(1,strict_still{:});
    Still(s) = 1;
    
    Run =  size_bin_loc;
    r = cat(1,strict_run{:});
    Run(r) = 1;
    
    %% Transitions
    trans_fr = transition_sec/dt;
    % Still --> Run
    [Transition_1,Transition_1_still,Transition_1_run] = tweak_transition(size_bin_loc,trans_fr,l2s_still ,f2s_run);
    % Run --> Still
    [Transition_2,Transition_2_still,Transition_2_run] = tweak_transition(size_bin_loc,trans_fr,f2s_still,l2s_run);
    
    %% Save binarize segments/transitions
    loc_names = {'Strict_still','Strict_run','Transition_still/run','Transition_still/run_1',...
        'Transition_still/run_2','Transition_run/still','Transition_run/still_1','Transition_run/still_2'};
    loc_vals = [Still,Run,Transition_1,Transition_1_still,Transition_1_run...
        Transition_2,Transition_2_run,Transition_2_still];
    locomotion_classification = array2table(loc_vals,'VariableNames',loc_names);
     trial.save_var('locomotion_classification',locomotion_classification)    
end
end

function [first_s,strict,last_s] = segmentation_state(state,state_sec,transition_sec,dt)
frames= state_sec;
state_periods = bwconncomp(state).PixelIdxList;
state_frames = arrayfun(@(s) length(s{:}), state_periods);
state_periods = state_periods(state_frames > frames);
trans_2s = transition_sec/dt;
% first 2s of the still periods
first_s = cellfun(@(s) s(1:trans_2s,:),state_periods,'UniformOutput',false);
% last 2s of the still period
last_s = cellfun(@(s) s(end-trans_2s+1:end,:),state_periods,'UniformOutput',false);
% strictly still period
strict = cellfun(@(s) s(trans_2s+1:end - trans_2s),state_periods,'UniformOutput',false);
% eliminate transitions at the start/end of the trace
if ~isempty(first_s) && first_s{1}(1) == 1
    first_s(1) = [];
end
if ~isempty(last_s) && last_s{end}(end) == length(state)
    last_s(end) = [];
end
end

function [Transition,part_s,part_r] = tweak_transition(size_trace,trans_nfr, part_still,part_run)
Transition = size_trace;
part_s = size_trace;
part_r = size_trace;
t_s = cat(1,part_still{:});
t_r = cat(1,part_run{:});
t = [t_s;t_r];
Transition(t) = 1;
% check that the 2 parts of the transition are present (if not, remove transition)
t_segs = bwconncomp(Transition).PixelIdxList;
if all(cellfun(@(s) length(s),t_segs) == 2*trans_nfr) % 80 frames
    part_s(t_s) = 1;
    part_r(t_r) = 1;
else
    t_idx = cellfun(@length,t_segs) == trans_nfr;
    c = t_segs(t_idx);
    c = cell2mat(c);
    mat_still = cell2mat(part_still);
    mat_run= cell2mat(part_run);
    idx_s = ~all(ismember(mat_still,c));
    idx_r = ~all(ismember(mat_run,c));
    t_s = cat(1,part_still{idx_s});
    t_r = cat(1,part_run{idx_r});
    t = [t_s;t_r];
    part_s(t_s) = 1;
    part_r(t_r) = 1;
    Transition = size_trace; % clear Transiiton
    Transition(t) = 1;
end
end