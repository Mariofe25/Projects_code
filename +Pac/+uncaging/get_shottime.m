function shottime = get_shottime(ts)
    padding = 3;
    
    if ~ts.has_var('channel_traces')
        disp("Calculating shot time..")
        begonia.processing.roi.extract_channel_traces(ts);
    end
    
    traces = ts.load_var('channel_traces');
    ch3 = traces.Data(:,2);
    [~, max_frame] = max(ch3);
    
    shottime = struct();
    shottime.start = max_frame - padding;
    shottime.end = max_frame + padding;
end

