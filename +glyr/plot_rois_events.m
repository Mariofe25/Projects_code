function plot_rois_events(mtab,roi_type,do_save,out_path)
% grab neuron or astrocyte rois from multitab and plot the events in a heatmap. Rois are 
% segmented by experimetnal state and behaviour state 
import begonia.logging.log

if nargin < 2 || isempty(roi_type), roi_type = "neurons";end
if nargin < 3, do_save = false;end

n_fovs = unique(mtab.fov,'stable');
for f = 1: numel(n_fovs)
    log(1,'Creating plot with astrocyte events by experimental category and behaviour. FoV: %s'...
       ,n_fovs(f))
    try
        fov = mtab(mtab.fov == n_fovs(f),:);
        mouse = unique(fov.mouse);
        fv = unique(fov.fov);
        exp_cat = unique(fov.exp_category);
        
        % Get rois by rois class (neurons or astrocytes)
        if roi_type == "neurons"
            rt = "neurons";
            fov = fov(startsWith(fov.roi_type,"N"),:);
            fov(fov.roi_type == "ND",:) = [];
        else
            rt = "astrocytes";
            fov = fov(~startsWith(fov.roi_type,"N"),:);
            fov(fov.roi_type == "Gp",:) = [];
        end
        
        % Unique rois types (NS, NS_dnt,Np / AS,AE,AP)
        rois_t = unique(fov.roi_type);
        if rois_t(1) == "NS", rois_t(1) = "NS "; end
        
        % Get number of rois
        r_id = unique(fov.roi_short_name);
       
        r_1 = sum(contains(r_id,rois_t(1)));
        % this may result in error if the number of roi types is less than
        % 3. Work around... agg
        try
            r_2 = sum(contains(r_id,rois_t(2)));
        catch
            rois_t(2) = "non";
            r_2 = 0;
        end
        try
            r_3 = sum(contains(r_id,rois_t(3)));
        catch
            rois_t(3) = "non";
            r_3 = 0;           
        end
        
        % Remove rois with no events
        for i = 1:numel(r_id)
            roi = [fov.events{fov.roi_short_name == r_id(i)}];
            if isempty(roi)
                fov(fov.roi_short_name == r_id(i),:) = [];
            end
        end
        
        % do not plot if there are no events. Continue to next fov
        if isempty(fov),log(1,'FoV %d has no roi with events',fv), continue, end
        
        % Number of rois with events
        r_id = unique(fov.roi_short_name);
        r1 = sum(contains(r_id,rois_t(1)));
        
        try
            r2 = sum(contains(r_id,rois_t(2)));
        catch
            rois_t(2) = "non";
            r2 = 0;
        end
        try
            r3 = sum(contains(r_id,rois_t(3)));
        catch
            rois_t(3) = "non";
            r3 = 0;           
        end
        % Ease access to number of events
        fov.n_events = cellfun(@length,fov.events);
        
        % Plot  number of events in each roi
        evs = [];
        for n = 1:numel(r_id)
            % Get individual rois
            roi = fov(fov.roi_short_name == r_id(n),:);
            
            % Extend array n events value to match the length of the trace
            len_trace = cellfun(@length,roi.trace);
            e = arrayfun(@(w,e) repmat(w,e,1),roi.n_events,len_trace,'UniformOutput',false);
            evs(:,n) = vertcat(e{:});
            
            % Extend array behaviour category  and experimental state
            if n == 1
                ex = arrayfun(@(w,e) repmat(w,e,1),roi.exp_state,len_trace,'UniformOutput',false);
                exp = vertcat(ex{:});
                
                b = arrayfun(@(w,e) repmat(w,e,1),roi.seg_category,len_trace,'UniformOutput',false);
                behav = vertcat(b{:});
            end
        end
        
        %% Plot events
        fig = figure("Position",[1000 702 900 635],"Color",[1 1 1]);
        layout = tiledlayout(3, 1, "tilespacing", "compact");
        s = sprintf('mouse: %s\nFoV: %s %s\n%s: %s: %d/%d   %s: %d/%d  %s: %d/%d',...
            mouse,fv,exp_cat,rt,rois_t(1),r1,r_1,rois_t(2),r2,...
            r_2,rois_t(3),r3,r_3);
        title(layout,roi_type + " Events by exp & behav state",s)
        
        % Colors behaviour state
        behav_order = ["Still","Still-Whisking","Transition_still_motion",...
            "Motion","Run","Transition_motion_still"];
        c = glyr.plot.brewermap(6,'Paired');   
        c = num2cell(c,2);
        behav_c = containers.Map(behav_order,c);
        
        % Color exp state
        exp_state = ["Baseline","Stimulation","Post-Stimulation"];
        d = {[0.5,0.5,0.5];[0,0,0];[0.3 0.3 0.3]};
        exp_d = containers.Map(string(exp_state),d);
        
        % Find the change in behaviour state array
        [~,r] = ismember(string(behav), behav_order);
        change = find(ischange(r));
        change = [0;change];
        
        % Find the change in experimetnal state array
        [~,ex] = ismember(exp, exp_state);
        exp_change = find(ischange(ex));
        exp_change = [0;exp_change];
        
        % Plot experimetnal state
        ax1 = nexttile(1);
        for j = 1:numel(exp_change)
            if j < numel(exp_change)
                x_e = [exp_change(j) exp_change(j + 1)-1];
            else
                x_e = [exp_change(j) length(ex)];
            end
            y_e = [0.05 0.05];
            d_idx = unique(exp(x_e(2:end)));
            line(x_e, y_e,'Color',exp_d(d_idx),'Clipping','off','LineWidth',20);
            hold on
        end
        
        % Plot behaviour state
        for i = 1:numel(change)
            if i < numel(change)
                x_b = [change(i) change(i + 1)-1];
            else
                x_b = [change(i) length(behav)];
            end
            
            y_b = [0 0];
            c_idx = string(unique(behav(x_b(2:end))));
            line(x_b, y_b,'Color',behav_c(c_idx),'Clipping','off','LineWidth',30);
        end
        
        ylim([0 0.3])
        xlim ([0 length(evs)])
        ax1.Visible = "off";
        
        % State legends
        for i = 1:numel(exp_state)
            h(i) = plot(NaN,'square', ...
                'MarkerSize', 10, ...
                'MarkerEdgeColor',exp_d(exp_state(i)), ...
                'MarkerFaceColor',exp_d(exp_state(i)), ...
                'DisplayName', exp_state(i));
        end
        
        for i = 1:numel(behav_order)
            bb =  behav_order(i);
            hh(i) = plot(NaN,'square', ...
                'MarkerSize', 10, ...
                'MarkerEdgeColor',behav_c(bb), ...
                'MarkerFaceColor',behav_c(bb), ...
                'DisplayName',bb);
        end
        hold off
        
        % Heatmap Events
        ax2 = nexttile(2,[2,1]);
        im = imagesc(ax2,evs');
        xl = im.Parent.XTickLabel;
        xl = double(string(xl)) * unique(fov.trace_dt);
        im.Parent.XTickLabel = round(xl);
        xlabel("Time(sec)")
        colormap(begonia.colormaps.magma);
        cb = colorbar;
        ylabel(cb,"Events","Rotation",270);
        cb.Label.Position(1) = 4;
        
        % ylabel
        neu = split(r_id," ");
        neu = neu(:,1);
        ns_types =  unique(neu,"stable");
        ns_type_start = arrayfun(@(tp) find(neu == tp, 1, 'first'), ns_types);
        yticks(ns_type_start); yticklabels(ns_types);
        
        % Legends are ouput here (if ouput before the heatmap it was messing the
        % plots...)
        dummy_ax = axes('Position',get(ax1,'Position'),'Visible','off');
        g = legend(ax1,h,'Box','off','NumColumns',1,'Location','west');
        gg = legend(dummy_ax,hh,'Box','off','NumColumns',2,'Location','east');
        
        title(g,'exp state')
        title(gg,"behaviour state")
        
        if do_save
            if nargin == 4 && ~isempty(out_path)  
                p = out_path;
            else
                p = "/Volumes/GlyR/GlyR project/Plots/Events";
                p = sprintf('%s/%s/%s',p,unique(fov.virus),unique(fov.exp_category));
            end
            filename_signal = roi_type + "/fov_events_" + n_fovs(f) ;
            outpng_1 = fullfile(p, [char(filename_signal) '.png']);
            begonia.path.make_dirs( outpng_1);
            print(fig, outpng_1, '-r300', '-dpng');
            % clean up:
            delete(fig)
        end
    catch err
        err.message
        warning("Check FOV: " + n_fovs(f))
    end
end
log(1,'Done!')
end