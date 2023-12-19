function  align2onset_locomotion(tss)
% Does the transition to motion/run cause an increase in the ∆f/f of each
% roi type?
% align traces to the start of motion/run using the transition still_motion
% category. Take 2 seconds before the transition and 3 seconds after the
% transition. Average data points. Each roi can have multiple transitions in
% baseline and stimulation and also in different tseries.
% First grab a tseires and average same frames of the same roi from/to the
% transition. Also average with the other tseries where the roi is present.
% Last step is to plot the average ± SD of each roi type
r = 0;
rr = length(tss);
for ts = tss
    r = r +1;
    begonia.logging.backwrite(1,'Aligning roi traces to locomotion onset %d/%d tseries',r,rr)
    m = ts.load_var("multitab_segmented");
    m(m.exp_state == "Post-Stimulation",:) = [];
    times = unique(m(:,{'seg_start_f','seg_end_f','seg_category','exp_state'}'));
    times = sortrows(times,'seg_start_f','ascend');
    fs = 30;
    % before_idx = trans_idx - 1;
    
    % Remove transitions that are to close to the stimulation and to the end
    % of the stimulation. Since there are 3sec post-onset and the trans is 1 sec,
    % remove cases with less than 3 sec after the end of trans and trans with
    % less than 1 sec;
    
    % trans too close to stimulation period. first check if there is any
    % transition in Baselne
    if any(times.exp_state == "Baseline" & times.seg_category == "Transition_still_motion")
        stim_start = times.seg_start_f(times.exp_state == "Stimulation");
        stim_end = times.seg_end_f(times.exp_state == "Stimulation");
        last_base = times.seg_end_f(times.exp_state == "Baseline" &...
            times.seg_category == "Transition_still_motion");
        last_base_idx = last_base(end) + 3*fs > stim_start(1);
        if last_base_idx
            times(times.seg_end_f == last_base(end),:) = [];
        end
    end
    
    % trans too close to the end of the stimulation. Check for trans in
    % Stimulation first
    if any(times.exp_state == "Stimulation" & times.seg_category == "Transition_still_motion")
        last_stim = times.seg_end_f(times.exp_state == "Stimulation" &...
            times.seg_category == "Transition_still_motion");
        last_stim_idx = last_stim(end) + 3*fs > stim_end(end);
        if last_stim_idx
            times(times.seg_end_f == last_stim(end),:) = [];
        end
    end
    
    % trans with post motion segment too short (< 3sec)
    trans_idx = find(times.seg_category == "Transition_still_motion");
    trans_end = times.seg_end_f(trans_idx);
    seg_dur = trans_end + 3*fs;
    to_remove = false(length(seg_dur));
    for i= 1:length(seg_dur)
        is_loc = times.seg_category(times.seg_start_f <= seg_dur(i) &...
            times.seg_end_f >= seg_dur(i));
        if is_loc == "Still" || is_loc == "Still-Whisking"
            to_remove(i) = true;
        else
            to_remove(i) = false;
        end
    end
    trans_idx(to_remove) = [];
    
    
    % Load non segmented multitab to 
    tab = ts.load_var('multitab');
    tab(tab.category ~= "ca-roi-dff",:) = [];
    
    %  Get the trnasitions traces and the post transitions traces
    before  = cell(1,length(trans_idx));
    after = cell(1,length(trans_idx));
    for i = 1:length(trans_idx)
        before{i} = cellfun(@(s) s(times.seg_start_f(trans_idx(i)):...
            times.seg_end_f(trans_idx(i))),tab.trace,"UniformOutput",false);
        
        after{i} = cellfun(@(s) s(times.seg_end_f(trans_idx(i)) + 1:...
            times.seg_end_f(trans_idx(i))+7*fs) ,tab.trace,"UniformOutput",false);
    end
    
    % Split by experimental state
    sts = times.exp_state(trans_idx);
    base_idx = sts == "Baseline";
    stim_idx = sts == "Stimulation";
    if sum(base_idx) > 0
        base_before = mean_merge(tab,before(base_idx));
        base_after = mean_merge(tab,after(base_idx));
    else
        base_before = repmat({nan(1*fs,1)},height(tab),1);
        base_after =repmat({nan(7*fs,1)},height(tab),1);
    end
    
    if sum(stim_idx) > 0
        stim_before = mean_merge(tab,before(stim_idx));
        stim_after = mean_merge(tab,after(stim_idx));
    else
        stim_before = repmat({nan(1*fs,1)},height(tab),1);
        stim_after = repmat({nan(7*fs,1)},height(tab),1);
    end
    
    % make table that includes the before/after traces in baseline and
    % stimulation
    type = tab.roi_type;
    name = tab.roi_short_name;
    align_tab = table(type,name,base_before,base_after,stim_before,stim_after);
    
    ts.save_var("trans_tab",align_tab)
    
end
end

function out =  mean_merge(tab,traces)
for i = 1: height(tab)
    for j = 1:length(traces)
        b{i,j} = traces{j}{i};
    end
end

% Sometimes the size of the segments is not the same (due to previous
% segmentations processes). Make them equal size by including NaNs at the
% start (usually it happens in the stimulation, that's why at the start)
s = unique(cellfun(@length,b),'stable');
if numel(s) > 1
    [maxx,in] = max(s);
    for k = 1:size(b,2)
        if k == in, continue;end
        for c = 1:length(b)
            ll = cellfun(@length,b(c,k));
            b{c,k} = [nan(maxx - ll,1);b{c,k}];
        end
    end
end

% merge roi transitions
for l = 1:length(b)
    bb{l,1} = [b{l,:}];
end
out = cellfun(@(s) mean(s,2,'omitnan'),bb,'UniformOutput',false);
end