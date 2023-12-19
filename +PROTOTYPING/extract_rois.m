function extract_rois(tss)
clear rois;
begonia.util.logging.set_global_level(2)
% tss = gdata.dcat.get_data(tss);
tss_valid = tss(tss.has_var('roi_array'));
disp(length(tss_valid) + " tseries with roi_array found")
%row = 1;
for i = 1:length(tss_valid)
    try
        ts = tss_valid(i);
        if ~ts.has_var('rois') || ts.dl_changelog('roi_array') > ts.dl_changelog('rois')
            roi_array = ts.load_var('roi_array');
            if any(ismember({roi_array.group}, 'NS'))
                do_donut = true;
            else
                do_donut = false;
            end
            rois = begonia.analysis.roi.extract_roi_signals(ts, do_donut); %#ok<*SAGROW>
            idx = [rois.roi_array.area] == 0;
            rois.roi_array = rois.roi_array(~idx);
            rois.raw_signals.Data = rois.raw_signals.Data(:,~idx);
            rois.dff_signals.Data = rois.dff_signals.Data(:,~idx);
            ts.save_var('rois', rois);
        else
            disp(ts.path + " already has rois up to date")
        end
        %         row = row + 1;
    catch err
        disp(err.message);
        continue;
    end
    disp("ROIs from " + ts.name + " done");
end
end