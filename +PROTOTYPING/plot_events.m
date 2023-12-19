function plot_events(traces,events)
% plot rois with events
idx = unique([events.trace_idx]);

traces = traces(idx,:);

figure
for i = 1:size(traces,1)
    
    trace = traces(i,:);
    
    event = events([events.trace_idx]== idx(i));
    
    plot(trace)
    
    hold on
    for e = 1:numel(event)
        yy = trace(event(e).x_start_idx: event(e).x_end_idx);
        plot(event(e).x_start_idx:event(e).x_end_idx,yy,'r')
        plot(event(e).x_start_idx,0,'bo','MarkerSize',5,'MarkerFaceColor','b')
    end
    
    ylabel('dff')
    xlabel('frames #')
   hold off
    
end
end