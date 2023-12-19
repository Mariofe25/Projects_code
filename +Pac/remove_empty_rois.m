function remove_empty_rois(tss)
for ts = tss    
    rois = ts.load_var('roi_table');
    rois(rois.area_px2 == 0,:) = [];    
    ts.save_var('roi_table',rois)       
end   
end
