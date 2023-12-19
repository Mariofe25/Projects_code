function remove_uncaging_vars(tss)

for ts = tss
    rois = ts.load_var('roi_table');
    if any(string(rois.Properties.VariableNames) == "roi_uncaging")
        rois = removevars(rois,{'roi_uncaging','shot_distance_px'});
        ts.save_var('roi_table',rois)
    else
        continue
    end
end
end