function ca_state = ca_by_state(tss)

for ts = tss
    % ca traces & roi types
    if ts.has_var("multitab")
        mtab = ts.load_var("multitab");
        mtab = sortrows(mtab,'roi_type');
        ca_traces = mtab.trace(mtab.category == "ca-roi-dff");
        ca_traces = horzcat(ca_traces{:});
        roi_type = mtab.roi_type(mtab.category == "ca-roi-dff");
        
        % states
        state = mtab.trace{mtab.category == "locomotion"};
        whisk = mtab.trace{mtab.category == "whisking"};
        
        still_idx = state == "Still" & ~whisk;
        still_whisk_idx = state == "Still" & whisk;
        run_idx = state == "Run";
        trans_still_run_idx = state == "Transition_still/run_1" |...
            state == "Transition_still/run_2";
        
        
        % Struct with ca signlas by locomotion state
        ca_state = struct;
        
        ca_state.still = ca_traces(still_idx,:);
        ca_state.still_whisk = ca_traces(still_whisk_idx,:);
        ca_state.run = ca_traces(run_idx,:);
        ca_state.trans_still_run = ca_traces(trans_still_run_idx,:);
        ca_state.roi_type = roi_type;
        
        ts.save_var("ca_state",ca_state)
    else
        warning(ts.name + " does not have multitab")
        continue
    end
end

