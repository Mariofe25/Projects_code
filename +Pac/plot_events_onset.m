function plot_events_onset(tss,do_save)

if nargin < 2, do_save = true; end
for ts = tss
    tab = ts.load_var('multitab_segmented');
    t = ts.load_var('multitab');
    dt = unique(tab.trace_dt);
    tab_loc = t.trace{t.category == "locomotion"};
    tab_whisk = t.trace{t.category == "whisking"};
    tab_loc(tab_loc == "Still" & tab_whisk) = "Still-Whisking";
    loc_1 = tab_loc(1);
    tab_locs = double(tab_loc);
    
    loc_change = find(ischange(tab_locs));
    
    locomotion_state = [loc_1;tab_loc(loc_change)];
    start_frame = [1;loc_change];
    end_frame = [loc_change - 1;length(tab_loc)];
    deltat = repmat(dt,numel(locomotion_state),1);
    start_sec = (start_frame * dt) - dt;
    end_sec = (end_frame * dt) - dt;
    
    behav = table(locomotion_state,start_frame,end_frame,deltat,...
        start_sec,end_sec);
    
    % Remove rois w/o events
    tab(cellfun(@isempty,tab.events),:) = [];
    tab(tab.roi_type == "ND",:) = [];
    tab(tab.roi_type == "Np",:) = [];
    tab(tab.roi_type == "NS-dnt",:) = [];
    
    % Make event table w. onset column
    events = [tab.events{:}];
    if ~isempty(events)
        onset = [events.x_start]';
    else
        continue
    end
    
    l_ev = cellfun(@length,tab.events);
    type = [tab.roi_type];
    id = [tab.roi_id];
    
    types = arrayfun(@(a,s) repmat(a,s,1),type,l_ev,'UniformOutput',false);
    types = vertcat(types{:});
    
    id = arrayfun(@(a,s) repmat(a,s,1),id,l_ev,'UniformOutput',false);
    id = vertcat(id{:});
    
    evs_tab = table(id,types,onset);
    evs_tab = sortrows(evs_tab,'types');
    
    tab_rois = unique(evs_tab.types);
    
    % Rois colors
    Pac.plot.roi_type_colors
    
    evs_tab.color = cell(height(evs_tab),1);   
    for i = 1:length(tab_rois)
        idx = evs_tab.types == tab_rois(i);
        evs_tab.color(idx) = {roi_colors(tab_rois(i))};
    end
    fig = figure('Position',[968 1064 1394 270]);
    s = scatter(evs_tab.onset,1:height(evs_tab),75,cell2mat(evs_tab.color),'filled',...
        'MarkerEdgeColor','k','LineWidth',1);
    hold on
    h = [];
    for i = 1:length(tab_rois)
        h{i} = plot(NaN,'o', ...
            'MarkerSize', 10, ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceColor',roi_colors(tab_rois(i)), ...
            'DisplayName', char(tab_rois(i)));
    end

    [~,p] = Pac.plot.plot_behaviour(ts,1,0,0);
    
    title("Events onset  " + ts.name)
    xlabel("Time(sec)")
    ylabel("RoIs")
        
    l = [[h{:}],p];
    
    legend(l,"Location",'eastoutside');
    
    
    if do_save
        p = '/Volumes/Xiaoyi1/PAC/Analysis/Event_onset';
        filename =  "Events_onset_" + ts.name;
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
    end
    
end
end