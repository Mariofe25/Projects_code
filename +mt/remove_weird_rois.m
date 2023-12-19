function remove_weird_rois(tss)
for ts = tss    
    dff = ts.load_var("roi_signals_dff");
    mtab = ts.load_var("multitab");
    
    f0 = dff.f0 < 50;
    
    if any(f0)
        roi_id =  dff.roi_id(f0);
        kill_idx = ismember(mtab.roi_id,roi_id);
        mtab(kill_idx,:) = [];
       ts.save_var("multitab",mtab)      
    else
        continue
    end
end
end