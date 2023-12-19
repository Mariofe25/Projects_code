function reassingn_roi_id(tss,reps)

fovs = unique(reps.fov,'stable');

tss_fovs = tss.load_var("RFOV");
tss_fovs = string(tss_fovs);

for i = 1:length(fovs)
    ts = tss(tss_fovs == fovs(i));
    roi_tab = ts(1).load_var('roi_table');
    type = roi_tab.type;
    
    ids = strings(length(type),1);
    for j = 1:length(type)
        ids(j) = string(begonia.util.make_snowflake_id(type(j)));
    end
    
    l1 = roi_tab.short_name;
    for t = 1:length(ts)
        tab = ts(t).load_var('roi_table');
        
        % make sure that tab rows are in the same order        
        l2 = tab.short_name;
        is_same = l1 == l2;
        
        if all(is_same)
            tab.short_name = ids;
        else
            [~,ord] = ismember(l1,l2);
            tab = tab(ord,:);
            tab.short_name = ids;
        end
        %
        ts(t).save_var('roi_table',tab)
        
        % Also fix the donut rois
        if ts(t).has_var('donut_dff')
            donut = ts(t).load_var('donut_dff');
            ns_idx = tab.type == "NS";
            donut_id = replace(tab.short_name(ns_idx),"NS","NS-dnt");
            donut.short_name = donut_id;
            ts(t).save_var('donut_dff',donut)
        end
    end
end
end