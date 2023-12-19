function  align2locon_v2(tss,exp_state)
% it finds the idxs of the transitions to locomotion. Each trace is
% integrated by 'before', 'trans'(1sec) and 'after' segments(INDETERMINATED)
import begonia.logging.backwrite
r = 0;
rr = length(tss);
for ts = tss
    r = r +1;
    backwrite(1,'Grabbing %s transitions from tseries: %d/%d',exp_state,r,rr)
    %     begonia.logging.backwrite(1,'Aligning roi traces to locomotion onset %d/%d tseries',r,rr)
    m = ts.load_var("multitab_segmented");
    mtab = ts.load_var("multitab");
    loc = mtab.trace{mtab.category == "locomotion"};
    m = m(m.exp_state == exp_state,:);
    times = unique(m(:,{'seg_start_f','seg_end_f','seg_category','exp_state'}'));
    times = sortrows(times,'seg_start_f','ascend');
    fs = 30;
    
    % Find transitions
    
    % Eliminate 1st transition if there is no before segment possible
    if times.seg_category(1) == "Transition_still_motion"
        times(1,:) = [];
    end
    trans_idx = find(times.seg_category == "Transition_still_motion");
    
    if any(trans_idx)
        % eliminate transitions at the end of the table (aka at the end of
        % Baseline or Stimulation)
        if trans_idx(end) == height(times)
            trans_idx(end) = [];
            if isempty(trans_idx)
                continue
            end
        end
        % eliminate trans_idx = 1. Menaing no before segment possible
%         rm_idx = trans_idx == 1;
%         trans_idx(rm_idx) = [];
            
        trans_start = times.seg_start_f(trans_idx);
        trans_end = times.seg_end_f(trans_idx);
        %         trans = arrayfun(@(s,f) s:f,trans_start,trans_end,'UniformOutput',false);
        trans_length = trans_end - trans_start + 1;
        
        % before transition, find the frames until it gets to a previous
        % to Motion/Run
        before_trans = arrayfun(@(s) find(times.seg_end_f < times.seg_start_f(s) & ...
            (times.seg_category == "Motion" | times.seg_category == "Run"),1,'last')...
            + 1,trans_idx,'UniformOutput',false);
        
        if isempty(before_trans{1})
            before_trans{1} = 1;
        end
        
        before_trans = [before_trans{:}];
        before_start = times.seg_start_f(before_trans);
        before_end = trans_start - 1;
        
        % after transitions (Motion/run), find the frames until it gets
        % to still or still-whisking
        after_trans = arrayfun(@(s) find(times.seg_start_f > times.seg_end_f(s) & ...
            (times.seg_category == "Still" | times.seg_category == "Still-Whisking"),1)...
            -1,trans_idx,'UniformOutput',false);


        
        % if there is no still/still-whisking segment, it is because
        % there is a experiment state transition (last tab row is motion/run).
        if isempty(after_trans{end})
            after_trans{end} = height(times);
        end
        
        after_trans = [after_trans{:}];
        after_start = trans_end + 1;
        after_end = times.seg_end_f(after_trans);
        
        % generate id for each transition
        ids = repmat("",length(trans_start),1);
        for i = 1:length(trans_start)
            ids(i) = string(begonia.util.make_snowflake_id('trans'));
        end
        
        % grab values from before, trans, after indx. Ensure that before,
        % trans traces have the correct length and that before, after only
        % contains the correct behaviour state.
        
        % Trans segment. Make it 1 sec. If there are not 30 frames,
        % start segment with NaNs
        tr = nan(30,1);
        before = cell(length(trans_start),1);
        trans = cell(length(trans_start),1);
        after = cell(length(trans_start),1);
        trace = cell(length(trans_start),1);
        for i = 1:length(trans_start)
            if trans_length(i) == 1*fs
                trans{i} = trans_start(i):trans_end(i);
            elseif trans_length(i) < 1*fs
                trans{i} = tr;
                trans{i}(1*fs + 1 - trans_length(i):length(tr)) = trans_start(i):trans_end(i);
                trans{i} =  trans{i}';
            else
                trans{i} = trans_start(i):trans_start(i) + 1*fs - 1;
            end
            
            % before segment
            before{i} = before_start(i):before_end(i);
            
            % before segments that start with 1 usually have higher df/f.
            % Eliminate the first 3 sec of before segments when possibe
            if before{i}(1) == 1
                if length(before{i}) < 3*fs
                    before{i} = nan;
                else
                    before{i} = before{i}(3*fs + 1:end);
                end          
            end
            
            % after segment
            after{i} = after_start(i):after_end(i);
            
            % join segment idx
            trace{i} = [before{i},trans{i},after{i}];
        end
        
        % grab mouse an fov from mtab
        fov = repmat(unique(mtab.fov),length(trans),1);
        mouse = repmat(unique(mtab.mouse),length(trans),1);
        tseries = repmat(unique(mtab.entity),length(trans),1);
        
        % make table
        trans_tab = table(tseries,ids,fov,mouse,before,trans,after,trace);
        
        % save table
        ts.save_var("trans_tab_" + exp_state,trans_tab)
    else
        continue
    end    
end
end