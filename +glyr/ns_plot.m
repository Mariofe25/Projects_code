for i = 1:length(ts)
    %% Get rois and smooth neuron channel
    % load rois
    ts = ts(i);
    rois = begonia.processing.roi.load_processed_signals(ts);
    ns_rois = rois(rois.channel == 2 & rois.type == "NS",:);
    np_rois = rois(rois.channel == 2 & rois.type == "Np",:);
    donut_rois = ts.load_var('donut_dff');
    for j = 1:height(ns_rois)
        % Find closest np roi
        x_pos = ns_rois.center_x(j);
        y_pos = ns_rois.center_y(j);
        np_pos= [np_rois.center_x,np_rois.center_y];
        for k = 1:height(np_rois)
            dist(k) = pdist2([x_pos,y_pos],[np_pos(k,1),np_pos(k,2)]);
        end
        [~,I] = min(dist);
        % Subtract np
        ns_raw = ns_rois.signal_raw{j};
        f0 = ns_rois.f0(j);
        np_raw = np_rois.signal_raw{I};
        y = ns_raw';
        X = np_raw';
        b = (X'*X)\(X'*y);
        y_hat = X * b;
        trace = (y - y_hat)/f0;
        ns_np_subtracted = trace';
        %% Plotting
        fig = figure("Position",[1 340 1672 607]);
        title(ns_rois.short_name{j})
        subplot(3,3,1)
        plot(ns_raw)
        axis tight
        title("NS raw")
        subplot(3,3,4)
        plot(np_raw)
        axis tight
        title("Np raw")
        subplot(3,3,7)
        plot(ns_rois.signal_doughnut{j})
        axis tight
        title("NS donut raw")
        subplot(3,3,2)
        plot(smooth(ns_rois.signal_dff{j}))
        axis tight
        title("NS dff")
        subplot(3,3,5)
        plot(smooth(np_rois.signal_dff{I}))
        axis tight
        title("Np dff")
        subplot(3,3,8)
        plot(smooth(donut_rois.signal_donut_dff{j}))
        axis tight
        title("NS donut dff")
        subplot(3,3,3)
        plot(smooth(ns_rois.signal_subtracted_dff{j}))
        axis tight
        title("NS donut subtracted")
        subplot(3,3,6)
        plot(smooth(ns_np_subtracted))
        axis tight
        title("NS- Np subtracted")
        filename = sprintf("/Volumes/GlyR/Neuron ROI plots/%s/%s",ts.name,ns_rois.short_name(j));
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
    end
end