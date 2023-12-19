function signals = load_processed_signals(tss)
    import begonia.util.*;

    signals = table();
    for ts = to_loopable(tss)
        roi_table = ts.load_var("roi_table");

        % load the RoIs:
        signal = ts.load_var("roi_signals_raw");
        signal_dff = ts.load_var("roi_signals_dff");
        signal_doughnut = ts.load_var("roi_signals_doughnut");
        signal_dff_subtracted = ts.load_var("roi_signals_dff_subtracted");
        s = num2cell(ts.load_var("Spike_prob"),2);
        
        signal_spikes = num2cell(nan(height(signal),...
            cellfun(@length,signal.signal_raw(1))),2);
        
        signal_spikes(roi_table.type == "NS") = s;
        signal_spikes = table(signal_spikes);

        rois = join(roi_table, signal);
        rois = join(rois, signal_dff);
        rois = join(rois, signal_doughnut);
        rois = join(rois,signal_dff_subtracted);
        rois = [rois,signal_spikes];
        
        signals = [signals ; rois];
    end
end

