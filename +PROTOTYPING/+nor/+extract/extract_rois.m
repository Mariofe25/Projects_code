clear rois;

begonia.util.logging.set_global_level(2)
% tss = dcat.get_data(stss);
tss_valid = tss(tss.has_var('roi_array'));

% TIP: if you want ot imoplement this in the future, try comparing the
% dates ts.dl_changelog('roi_array') and ts.dl_changelog('rois') to
% determine if you need to-re-run it.

row = 1;
for i = 1:length(tss_valid)
    try
        ts = tss_valid(i);
        if ~ts.has_var('rois') 
            rois(row) = begonia.analysis.roi.extract_roi_signals(ts, true);   %#ok<*SAGROW>
            ts.save_var('rois', rois(row));
        else
            rois(row) = ts.load_var('rois');
        end
        
        row = row + 1;
    catch err
       disp(err.message);
       continue;
    end
    
    disp("ROIs from " + ts.name + " done");
end

% if  exist('err','var') == 0
%    disp('All succeeded') 
% end














%ts.save_var(rois)
% % clear tseries;
% for i = 1:length(stacks)
%     tseries = stacks(i).get_data();
%     
%     signal = tseries.load_var('ca_signal_df_f0');
%     
%     break
% end
% 
% % rois = begonia.data_management.var2table(tseri es,'roi_array');