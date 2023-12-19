function events_corr2(tss,do_save)

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
    
    
    trial = glyr.rig.get_trials(ts);
    trial = trial{:};
    if trial.has_var("whisker_log")
        whisker = trial.load_var("whisker_log");
        wall_start =  seconds(whisker.start);
        wall_in = seconds(whisker.estimated_start);
        wall_out = seconds(whisker.stop);
    end
    
    % trial = glyr.rig.get_trials(ts);
    % trial = trial{:};
    % locomotion = trial.load_var('locomotion_tab');
    % whisking = trial.load_var('whisking_tab');
    
    % Remove rois w/o events
    tab(cellfun(@isempty,tab.events),:) = [];
    tab(tab.roi_type == "Gp",:) = [];
    tab(tab.roi_type == "ND",:) = [];
    
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
    
    rois = ["AE","AP","AS","NS","NS-dnt","Np"];
    ros_c = [0.8,1,0;0.4,1,0.3;0,1,0;1,0,0;1,0,1;1,0.4,0.5];
    ros_c = num2cell(ros_c,2);
    rois_color = containers.Map(rois,ros_c);
    
    evs_tab.color = cell(height(evs_tab),1);
    
    for i = 1:length(tab_rois)
        idx = evs_tab.types == tab_rois(i);
        evs_tab.color(idx) = {rois_color(tab_rois(i))};
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
            'MarkerFaceColor',rois_color(tab_rois(i)), ...
            'DisplayName', char(tab_rois(i)));
    end

    [~,p]  = glyr.plot.plot_behaviour(ts,0,0);
    
   
    xline(wall_start,'-k','LineWidth',2,'Label',"In")
    xline(wall_in,'-k','LineWidth',2,'Label',"Est. Start")
    xline(wall_out,'-k','LineWidth',2,'Label',"Out")
    title("Events onset  " + ts.name)
    xlabel("Time(sec)")
    ylabel("RoIs")
    
    
    l = [[h{:}],p];
    
    legend(l,"Location",'eastoutside');
    
    
    if do_save
        p = '/Volumes/GlyR/GlyR project/Plots/Event_onset';
        p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
        filename =  "Events_onset_" + ts.name;
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
    end
    
end
end