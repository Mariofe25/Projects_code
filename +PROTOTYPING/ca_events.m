function ca_events(mtab,data)
idx = cellfun(@isempty,data);
data(idx) = [];

for i = 1:length(data)
    
    roitraces = data{i}.trace(data{i}.category == "roitrace");
    
    for j = 1:length(roitraces)
        
        roi_trace = roitraces{j};
        
        % Smooth trace (sgolay filter, 1st order, window size)
        roi_filt = sgolayfilt(roi_trace,1,31);
        
        % Noise = df/f0 - low_pass filtered df/f0 (aka highpass filter)
        noise = roi_trace - roi_filt;
        noise = abs(noise);
        noise = prctile(noise,50);
        
        % Rule 1. is event if signal is higher than 3 times the noise signal
        r1 = roi_filt > 3*noise;
        % Rule 2. Is event if it is at least 0.3
        %r2 = roi_trace >= 0.3;
        
        ca_events = r1;%& r2;
        trace = ca_events;
        
        dt = unique(data{i}.delta_time);
        group_id = unique(data{i}.group_id);
        data_id = "ca_events-" + string(data{i}.data_id(j));
        category = "binarized_ca";
        
        mtab.update(trace,data_id, group_id, category,"", "binarize", dt);
        mtab.save()
    end
    
end

end