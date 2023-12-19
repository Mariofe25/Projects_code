function check_events(tss,do_random,n)
% plot traces with events to see how good is the event detection method
% used
if nargin < 3, n = 5; end
if nargin < 2, do_random = true; end
gen = unique(string(tss.load_var("genotype")));
for ts = tss
    mtab = ts.load_var('multitab');
    speed = mtab.trace{mtab.category == "speed"};
    whisker = mtab.trace{mtab.category == "whisker"};
    mtab = mtab(mtab.category == "ca-roi-dff",:);
    mtab(mtab.roi_type == "ND",:) = [];
    mtab(mtab.roi_type == "NS-dnt",:) = [];
    mtab(mtab.roi_type == "Np",:) = [];
    fs = 10;
    if do_random
        [u,idx] = unique(mtab.roi_type);
        idx = [idx;height(mtab)];
        slct_idx = cell(length(idx) - 1,1);
        for i = 1:numel(u)
            if idx(i + 1) - idx(i) >= n
                % ln = length(idx(i):idx(i+1) - 1)';
                slct_idx{i} = randperm(length(idx(i):idx(i+1) - 1),n) + idx(i) - 1;
                % slct_idx{i} = randperm(ln,round(ln*prc/100)) + idx(i) - 1;
            else
                slct_idx{i} = idx(i):idx(i+1) - 1;
            end
        end
        slct_idx = horzcat(slct_idx{:})';
        mtab = mtab(slct_idx,:);
    end

    for i = 1:height(mtab)
        roi_name = mtab.roi_short_name(i);
        % parameters = glyr.default_parameters;
        if startsWith(mtab.roi_type(i),"N")
            roi_type = "neurons";
            %filter = begonia.util.gausswin(parameters.neuron_sigma_smoothing*fs);
        else
            roi_type = "astrocytes";
            %filter = begonia.util.gausswin(parameters.astrocyte_sigma_highpass_window_1*fs);
        end
        trace = mtab.trace{i};
        events = mtab.events{i};
        fig = figure;
        fig.Position = [680 641 1178 357];
        if ~isempty(mtab.events{i})
            d = "detected";
        else
            d = "non_detected";
        end
        layout = tiledlayout(2,1,'TileSpacing','compact');
        nexttile()
        hold on
        t = 0:1/fs:length(trace)*1/fs - 1/fs;
        Pac.plot.plot_behaviour(ts,0,0,0)
        yyaxis right
        plot(t,trace,'LineWidth',1,'Color','k')
        %    plot(events.x_idx,event.y,'ro','MarkerSize',7,'MarkerFaceColor','r')
        %    plot(events.x_start_idx,y_plot,'bo','MarkerSize',7,'MarkerFaceColor','b')
        %    plot(events.x_end_idx,y_plot,'ko','MarkerSize',7,'MarkerFaceColor','k')
        for e = 1:numel(events)
            yy = trace(events(e).x_start_idx: events(e).x_end_idx);
            plot(t(events(e).x_start_idx:events(e).x_end_idx),yy,'r',"LineStyle","-",'LineWidth',1,'Marker','none')
            plot(t(events(e).x_start_idx),trace(events(e).x_start_idx),'bo','MarkerSize',5,'MarkerFaceColor','b')
            try
                plot(t(events(e).x_threshold_idx),trace(events(e).x_threshold_idx),'bo','MarkerSize',5,...
                    'MarkerFaceColor','g','MarkerEdgeColor','none');
            catch
            end
        end
        legend off
        ylabel('dff')
        xlabel('Time (s)')
        title(unique(mtab.mouse) + " " + ts.name, mtab.roi_short_name(i) + ...
            ": " + numel(events) + " event(s)")
        nexttile()
        yyaxis left
        plot(t,speed)
        xlabel('Time (sec)')
        ylabel('Speed cm/s')

        yyaxis right
        plot(t,whisker)
        ylabel('Whisking a.u')
        hold off

        % save it
        p = "/Volumes/Xiaoyi1/PAC/Analysis/Rois_events_" + gen;
        p = sprintf('%s/%s/%s/%s',p,ts.name,roi_type,d);
        filename = roi_name;
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
    end
end
end