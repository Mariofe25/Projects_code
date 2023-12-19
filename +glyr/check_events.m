% plot traces with events to see how good is the event detection method
% used
virus = unique(string(tss.load_var('virus')));
exp_state = unique(string(tss.load_var('drug')));

for ts = tss
    mtab = ts.load_var('multitab');
    mtab = mtab(mtab.category == "ca-roi-dff",:);
    mtab(mtab.roi_type == "ND",:) = [];
    mtab(mtab.roi_type == "Gp",:) = [];
    fs = 30;
    
    for i = 1:height(mtab)
        roi_name = mtab.roi_short_name(i);
        parameters = glyr.default_parameters;
        if startsWith(mtab.roi_type(i),"N")
            roi_type = "neurons";
            filter = begonia.util.gausswin(parameters.neuron_sigma_smoothing*fs);
        else
            roi_type = "astrocytes";
            filter = begonia.util.gausswin(parameters.astrocyte_sigma_highpass_window_1*fs);
        end
        trace = convn(mtab.trace{i},filter,'same');
        events = mtab.events{i};
        fig = figure;
        if ~isempty(mtab.events{i})
            d = "detected";
        else
            d = "non_detected";
        end
        hold on
        plot(trace)
        %    plot(events.x_idx,event.y,'ro','MarkerSize',7,'MarkerFaceColor','r')
        %    plot(events.x_start_idx,y_plot,'bo','MarkerSize',7,'MarkerFaceColor','b')
        %    plot(events.x_end_idx,y_plot,'ko','MarkerSize',7,'MarkerFaceColor','k')
        for e = 1:numel(events)
            yy = trace(events(e).x_start_idx: events(e).x_end_idx);
            plot(events(e).x_start_idx:events(e).x_end_idx,yy,'r')
            plot(events(e).x_start_idx,trace(events(e).x_start_idx),'bo','MarkerSize',2,'MarkerFaceColor','b')
            try
            plot(events(e).x_threshold_idx,trace(events(e).x_threshold_idx),'bo','MarkerSize',2,'MarkerFaceColor','g')
            catch
            end
        end
        
        ylabel('dff')
        xlabel('frames #')
        title(unique(mtab.mouse) + " " + ts.name, mtab.roi_short_name(i) + ...
            ": " + numel(events) + " event(s)")
        
        % save it
        p = "/Volumes/GlyR/GlyR project/Plots/Events_check/" + virus + ...
            "/" + exp_state;
        p = sprintf('%s/%s/%s/%s',p,ts.name,roi_type,d);
        filename = roi_name;
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
    end
end