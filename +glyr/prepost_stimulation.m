function prepost_stimulation(tss)
% select the tseries where the mouse is running/moving during the
% transition to locomotion and check for events and ∆f/f
import begonia.data_management.multitable.*
import begonia.logging.*
for ts = tss
    log(1,"Loading multitab from " + ts.name)
    tab = ts.load_var('multitab');
    dt = unique(tab.trace_dt);
    tab_loc = tab.trace{tab.category == "locomotion"};
    tab_whisk = tab.trace{tab.category == "whisking"};
    tab_loc(tab_loc == "Still" & tab_whisk) = "Still-Whisking";
    tab_loc = string(tab_loc);
    tab_exp_state = tab.trace{tab.category == "exp_state"};
    tab = tab(tab.category == "ca-roi-dff",:);
    
    
    %     % find start of stimulation
    %     trial = glyr.rig.get_trials(ts);
    %     trial = trial{:};
    %     if trial.has_var("whisker_log")
    %         whisker = trial.load_var("whisker_log");
    %         wall_start = whisker.start;
    % %         wall_in = whisker.estimated_start;
    % %         wall_out = whisker.stop;
    %         wall_start_idx = seconds(round(wall_start/dt));
    % %         wall_in_idx = seconds(round(wall_in/dt));
    % %         wall_out_idx = seconds(round(wall_out/dt));
    %         pre_s = wall_start - seconds(3);
    %         pre_e = wall_start - seconds(0.5);
    %         dur_s = wall_start;
    %         dur_e = wall_start + seconds(3);
    %         post_s = dur_e + seconds(1);
    %         post_e = post_s + seconds(3);
    %     end
    
    start_stim = find(tab_exp_state == "Stim",1,'first');
    
    % trace 2 sec to the stim start and 3-5 sec from it 
    check_trace = start_stim - 2/dt:start_stim + 5/dt;
    % Check that the mouse is moving ('run' or 'motion') during the
    % transition to stimulation 
    log(1,"Checking for locomotion state...")
   
    if ~any(tab_loc(stim) == "Run") && ~any(tab_loc(stim) == "Motion")...
            && ~any(tab_loc(stim) == "Transition_still_motion")
        log(1,"No motion found.")
        continue
    else
        s = tab_loc(stim);
        l = length(s);
        r = sum(s == "Run");
        m = sum(s == "Motion");
        sm = sum(s == "Transition_still_motion");
        t = r + m + sm;
        if t < 0.4*l, log(1,"Not enough motion found."); continue;end
    end
    
    % Segmetn de multitab: pre stimulation, while wall is coming in, after 3
    % seconds
    log(1,"Segmenting mtab 'Pre_wall', 'Early_wall', 'Late_wall'")
    pre = timerange(tab,pre_s,pre_e);
    dur = timerange(tab,dur_s,dur_e);
    post = timerange(tab,post_s,post_e);
    
    % Check if there is an event(s) in the segment
    log(1,"Checking for events...")
    pre = in_evs(pre);
    dur = in_evs(dur);
    post = in_evs(post);
    
    % Remove events that do not start in the segment
    pre = rmv_evs(pre);
    dur = rmv_evs(dur);
    post = rmv_evs(post);
    
    % Count number of events that start in the segment
    pre.n_events = cellfun(@length,pre.events);
    dur.n_events = cellfun(@length,dur.events);
    post.n_events = cellfun(@length,post.events);
    
    % Mean, max ∆F/F
    log(1,"Mean/Max segemnt...")
    pre = mean_max(pre);
    dur = mean_max(dur);
    post = mean_max(post);
    
    % add wall moment
    pre.wall_cat = repmat("Pre_wall",height(pre),1);
    dur.wall_cat = repmat("Early_wall",height(dur),1);
    post.wall_cat = repmat("Late_wall",height(dur),1);
    
    % Join tabs
    wall_mtab = [pre;dur;post];
    
    % Save it
    ts.save_var("mtab_wall",wall_mtab)
end
log(1,"Done!")
end

function mtab = in_evs(mtab)
m = height(mtab);
mtab.event_in = false(height(mtab),1);
for i = 1:m
    events = mtab.events{i};
    if ~isempty(events)
        is_in = [events.x_end_idx] > mtab.seg_start_f{i} & ...
            [events.x_end_idx] < mtab.seg_end_f{i};
        if any(is_in)
            mtab.event_in(i) = true;
        end
    else
        continue
    end
end
end

function mtab = rmv_evs(mtab)
m = height(mtab);
import begonia.logging.*;
for i = 1:m
    backwrite(2,'Filtering segments:%d/%d',i,m)
    events = mtab.events{i};
    if ~isempty(events)
        st =  mtab.seg_start_f{i};
        sp = mtab.seg_end_f{i};
        
        s = [events.x_start_idx] >= st  & [events.x_start_idx] < sp ;
        
        % Remove selected events
        events(~s) = [];
        mtab.events{i} = events;
        
        % If no remaining events in the struct, remove it
        if isempty(events)
            mtab.events{i} = [];
        end
    else
        continue
    end
end
end

function mtab = mean_max(mtab)
mtab.mean_trace = cellfun(@mean,mtab.trace);
mtab.max_trace = cellfun(@max,mtab.trace);
end
