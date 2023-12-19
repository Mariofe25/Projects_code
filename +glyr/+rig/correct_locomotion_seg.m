function correct_locomotion_seg(trials)
import begonia.logging.*
% Convert short motion segmets (<= 1sec) to run if they preceed run segs,
% fall within run segs or after run
n = 0;
for trial = trials
    n = n + 1;
    s = sprintf('Calculating mouse speed in deg/s: %d/%d',n,length(trials));
    backwrite(1,s)
    locomotion = trial.load_var("locomotion");
    motion  = locomotion == "Motion";
    motion_segs = bwconncomp(motion).PixelIdxList;

    % motion segs <= 1sec (20 frames). Keep the rest
    motion_duration = cellfun(@(s) length(s), motion_segs);
    motion_segs = motion_segs(motion_duration <= 20);

    if isempty(motion_segs), continue; end

    % motion segs first and last indices
    first_idx = cellfun(@(s) s(1),motion_segs);
    last_idx = cellfun(@(s) s(end),motion_segs);

    % 1st and last vector indices
    if first_idx(1) == 1, first_idx(1) = 2;end
    if last_idx(end) == length(locomotion), last_idx(end) = last_idx(end) -1; end

    % pre/post moiton segs states
    pre = locomotion(first_idx - 1);
    post = locomotion(last_idx + 1);

    % avoid removing startle responses (short motion segs). seg that
    % are not between run segs or trans and run. Update pre and post
    % 'startle idx' can be use to create the 'undefined' category (instead of
    % converting to 'still' category
    startle_idx =  pre == "Transition_still_motion" & post == "Still";
    motion_segs = motion_segs(~startle_idx);
    pre = pre(~startle_idx);
    post = post(~startle_idx);

    % Convert to 'run' category
    convert_idx = pre ~= "Still";
    motion_segs = motion_segs(convert_idx);
    to_run_idxs = vertcat(motion_segs{:});
    locomotion(to_run_idxs) = "Run";
    
    trial.save_var("locomotion",locomotion)
end
disp ('Done!')
end





