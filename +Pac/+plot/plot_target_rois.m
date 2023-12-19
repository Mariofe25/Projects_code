 function plot_target_rois(ts)

uncaging = ts.load_var("rois_target");
cat = uncaging.uncaging_category;
if ~any(cat == "target" | cat == "close")
    disp("No ROIs are 'target' or are close to the shot spot")
    return
end

% uncaging shot
uncaging_info =  ts.load_var('uncaging_info');
un_start = uncaging_info.Start;
%un_end = uncaging_info.End;

% roi signals
rois = begonia.processing.roi.load_processed_signals(ts);
try
rois.metadata =[];
catch
end
rois = join(rois,uncaging);

% target rois
target_rois = rois(rois.uncaging_category == "target",:);
if ~isempty(target_rois)
    targets = target_rois(:,{'signal_dff','type','short_name'});
    ns_t = targets.type == "NS";
    if any(ns_t)
        targets.signal_dff(ns_t) = target_rois.signal_subtracted_dff(ns_t);
    end
    target_signal = cell2mat(targets.signal_dff)';
    if size(target_signal,2) > 1
        n_targets = 0:size(target_signal,2)-1;
        n_targets = repmat(n_targets,length(target_signal),1);
        target_signal =  target_signal + n_targets;
    end
else
    disp("No ROIs are 'target'")
end

% close rois
close_rois = rois(rois.uncaging_category == "close",:);
if ~isempty(close_rois)
    close = close_rois(:,{'signal_dff','type','short_name'});
    ns_c = close.type == "NS";
    if any(ns_c)
        close.signal_dff(ns_c) = close_rois.signal_subtracted_dff(ns_c);
    end
    close_signal = cell2mat(close.signal_dff)';
    if size(close_signal,2) > 1
        n_close = 0:size( close_signal,2)-1;
        n_close = repmat(n_close,length(close_signal),1);
        close_signal =   close_signal + n_close;
    end
else
    disp("No ROIs less than 10px to the shot spot found")
end


% Plot
fig = figure("color", [0.84,0.90,0.95], "name", "Signal overview " + ts.name);
if ~isempty(target_rois) && ~isempty(close_rois)
    layout = tiledlayout(2, 1, "tilespacing", "compact");
    title(layout,ts.name);
    
    ax1 = nexttile();
    plot(target_signal)
    hold on
    xline(un_start,'-r')
    grid on
    title("Target ROI(s)"); xlabel("Frame (#)");
    ylabel("Df/f")
    legend(targets.short_name)
    axis tight
    
    
    ax2 = nexttile();
    plot(close_signal)
    hold on
    xline(un_start,'-r')
    grid on
    title("Close ROI(s)");
    xlabel("Frame (#)");
    ylabel("Df/f")
    legend(close.short_name)
    axis tight
    
    %linkaxes([ax1, ax2])
else  
    try
        signal = target_signal;
        s_type = targets.short_name;
        ti = "Target ROI(s)";
    catch
        signal = close_signal;
        s_type = close.short_name;
        ti ="Close ROI(s)";
    end
    plot(signal,'Color')
    hold on
    xline(un_start,'-r')
    grid on
    title(ti);
    xlabel("Frame (#)");
    ylabel("Df/f")
    legend(s_type)
    axis tight       
end
end