function has_target_rois(tss)
for ts = tss
    rois =  ts.load_var('rois_target');
    try
        astrocyte_rois = rois(rois.channel == 1,:);
        has_target = any(astrocyte_rois.uncaging_category == "target");
    catch err
        disp(err)
        continue
    end
    ts.save_var("roi_shot",has_target)
end

end