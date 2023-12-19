function align2locon(tss,exp_state)
% it finds the idxs of the transitions to locomotion. Each trace is
% composed of 'before' transiton (2 sec max), 'trans'(1sec) and 'after'
% trans (INDETERMINATED). 'after' seg can be modify later
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
        trans_start = times.seg_start_f(trans_idx);
        trans_end = times.seg_end_f(trans_idx);
        %         trans = arrayfun(@(s,f) s:f,trans_start,trans_end,'UniformOutput',false);
        trans_length = trans_end - trans_start + 1;
        
        % before transition 2secs
        before_frames = 2*fs;
        before_start = trans_start - before_frames;
        before_end = trans_start - 1;
        before_length = before_end - before_start + 1;
        
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
      
        % Add 1 extra sec at the end of the after transition segment
        after_end = times.seg_end_f(after_trans) +1*fs; 
        a_idx_end = after_end > times.seg_end_f(end);
        if any(a_idx_end)
            after_end(a_idx_end) = times.seg_end_f(end);
        end

        % generate id for each transition
        ids = repmat("",length(trans_start),1);
        for i = 1:length(trans_start)
            ids(i) = string(begonia.util.make_snowflake_id('trans'));
        end
        
        % grab values from before, trans, after indx. Ensure that before,
        % trans traces have the correct length and that before, after only
        % contains the correct behaviour state.
        
        % Trans segment. Make it 30 frames. If there are not 30 frames,
        % start segment with NaNs
        % Before segment. 60 frames
        tr = nan(30,1);
        bf = nan(before_frames,1);
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
            
            if before_length(i) == 2*fs
                before{i} = before_start(i):before_end(i);
            elseif before_length(i) < 2*fs
                before{i} = bf;
                before{i}(2*fs + 1 - before_length(i):length(bf)) = before_start(i):before_end(i);
            else
                before{i} = before_start(i):before_start(i) + 2*fs - 1;
            end
            before{i}(before{i} <= 0) = nan;
            
            % after segment.
            after{i} = after_start(i):after_end(i);
            
            % join segment idx
            trace{i} = [before{i},trans{i},after{i}];
        end
        
        % in the 'before' case, ensure that it only contains frames in the
        % still (convert others to nans)
        still_state = find(loc == "Still");
        for i = 1:length(before)
            idx = ismember(before{i},still_state);
            if ~all(idx)
                before{i}(~idx) = nan;
                trace{i}(~idx) = nan;
            end
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