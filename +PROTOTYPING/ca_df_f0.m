function ca_df_f0(gdata,tss)

% find the baseline = time before the sandpaper comes in
for ts = tss
    
    % get the rig data associated to the ts
    trial = glyr.rig.get_rig(gdata,tss(1));
    
    % get the time when the wall comes close to the mouse from
    % whisker logs (trimmed version)
%     whisk_log = trial.load_var('whisker_log');
%     idx_wall_in = find(whisk_log.wall,1,'first');
%     time_wall = whisk_log.tr(idx_wall_in);
%     time_wall = seconds(time_wall);
%     
    % get the raw rois data and drift correction trace
    raw_ca = ts.load_var('ca_signal');
    drift_correction_trace = ts.load_var('drift_correction_trace');
    signal = raw_ca.Data .* drift_correction_trace;
    
%     % baseline (from 0s to time_wall )
%     baseline_eidx = find(round(raw_ca.Time,1)== time_wall,1);
%     if isempty(baseline_eidx)
%         baseline_eidx = find(round(raw_ca.Time)== round(time_wall),1);    
%     end
%     baseline_ca = signal(1: baseline_eidx,:);
    
    % get f0 and df/f0
    % sgolay(signal,1st order,window size)
    signal_filter = sgolayfilt(signal,1,31);
    f0 = prctile(signal_filter,1); % 1st percentile of the sgolay filtered trace
    ca_dff = (signal-f0)./f0;
    ca_dff = timeseries(ca_dff,raw_ca.Time,'Name','ca_signal_df_f0');
%     f0 = mode(baseline_ca,1);
%     ca_dff = (signal-f0)./f0;
%     ca_dff = timeseries(ca_dff,raw_ca.Time,'Name','ca_signal_df_f0');
    
    ts.save_var("rois_dff_baseline_f0",ca_dff)  
    
end
end