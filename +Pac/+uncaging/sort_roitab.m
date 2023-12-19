function sort_roitab(tss)
% sort roi table by distance to the uncaging shot spot
for ts = tss
    if ts.has_var('rois_target')
        roi_table = ts.load_var('roi_table');
        try rois.metadata =[]; catch,end
        shot_distance = ts.load_var('rois_target');
        try  shot_distance.metadata =[]; catch,end
        shot_distance = sortrows(shot_distance,{'type','shot_distance'});
        rois = join(shot_distance,roi_table);
        vars_roi_table = string(roi_table.Properties.VariableNames);
        roi_table = rois(:,vars_roi_table);
        ts.save_var('roi_table',roi_table)
    end    
end   
end