function plot_fov_summary(mtab,do_save)
if nargin < 2, do_save = false; end

fovs = unique(mtab.fov);
for f = 1:numel(fovs)
    
    % bo = mtab(mtab.mouse == "BR",:);
    
    f1 = mtab(mtab.fov == fovs(f),:);
    
    f1 = f1(startsWith(f1.roi_type,"N"),:);
    f1(f1.roi_type == "ND",:) = [];
    
    n_id = unique(f1.roi_short_name);
    
    ns_1 = f1(f1.roi_short_name == n_id(1),:);
    
    total_sec = sum(ns_1.total_sec);
    
    
    % Colors behaviour state
    behav_order = ["Still","Still-Whisking","Transition_still_motion",...
        "Motion","Run","Transition_motion_still"];
    c = glyr.plot.brewermap(6,'Paired');
    c = num2cell(c,2);
    behav_c = containers.Map(behav_order,c);
    
    exp_state = ["Baseline","Stimulation","Post-Stimulation"];
    d = {[0.5,0.5,0.5];[0,0,0];[0.3 0.3 0.3]};
    exp_d = containers.Map(string(exp_state),d);
    
    %
    fig = figure("Position",[1000 355 1329 982]);
    layout = tiledlayout(2, 2, "tilespacing", "compact");
    title(layout,"FoV: " + unique(f1.fov) + " Summary")
    
    % Plot
    ax1 = nexttile();
    title(ax1,'Time per behaviour state and experimental state')
    ylabel('Time (sec)')
    xlabel('Experimental state')
    hold on
    for i = 1:length(exp_state)
        state = ns_1(ns_1.exp_state == exp_state(i),:);
        behav = zeros(height(state),3);
        for b = 1:length(state.seg_category)
            behav(b,:) = behav_c(string(state.seg_category(b)));
        end
        behav = num2cell(behav,2);
        p = bar(ax1,i,state.total_sec,'stacked','FaceColor','flat');
        set(p, {'CData'}, behav)
    end
    p = bar(i + 1, sum(ns_1.total_sec),'FaceColor','k');
    set(ax1,'XTick',1:4)
    set(ax1,'XTickLabel',[exp_state,"Total"])
    for i = 1:numel(behav_order)
        bb =  behav_order(i);
        hh(i) = plot(NaN,'square', ...
            'MarkerSize', 10, ...
            'MarkerEdgeColor',behav_c(bb), ...
            'MarkerFaceColor',behav_c(bb), ...
            'DisplayName',bb);
    end
    legend(ax1,hh,'Location','northwest')
    
    % Plot active neurons
    ax2 = nexttile();
    hold on
    title(ax2,"Number of active/inactive neurons (w/ ratio)")
    ylabel("Number of neurons")
    xlabel("RoI type")
    nu_type = unique(f1.roi_type);
    
    % Get number of rois
    n_ns = sum(contains(n_id,"NS "));
    n_ndt = sum(contains(n_id,"NS-"));
    n_np = sum(contains(n_id,"Np"));
    
    % Number of rois with events
    for i = 1:numel(n_id)
        roi = [f1.events{f1.roi_short_name == n_id(i)}];
        if isempty(roi)
            f1(f1.roi_short_name == n_id(i),:) = [];
        end
    end
    
    n_id = unique(f1.roi_short_name);
    nns = sum(contains(n_id,"NS "));
    nndt = sum(contains(n_id,"NS-"));
    nnp = sum(contains(n_id,"Np"));
 
    % rois with events
    ns = [nns,n_ns];
    ndt = [nndt,n_ndt];
    np = [nnp,n_np];
    
    rois = [ns;ndt;np];
    
    % plot num rois
    b  = bar(rois,'FaceColor','flat');
    b(1).FaceColor = [0.5,0.5,0.5];
    b(2).FaceColor = [0,0,0];
    
    % ratio active rois
    rat_rois = round(rois(:,1)./rois(:,2),2);
    y_pos = b(2).YEndPoints;
    x_pos = mean([b(1).XEndPoints;b(2).XEndPoints]);
    rat_labels = string(rat_rois);
    text(x_pos,y_pos,rat_labels,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    ax2.XTick = 1:length(nu_type);
    set(ax2,'XTickLabel',nu_type)
    
    legend(ax2,["Active Neurons", "Total Neurons"]);
    
    % Plot events frequency
    ax3 = nexttile();
    hold on
    title("Events frequency by experimental state")
    ylabel("Events/sec")
    f1 = glyr.get_event_freq(f1);
    boxplot(ax3,f1.events_sec,f1.exp_state,'PlotStyle','compact',...
        "OutlierSize",15,"LabelOrientation",'horizontal')
    
    
    ax4 = nexttile();
    hold on
    title("Total number of events per experimetnal state")
    symb = {[1,0,0],[0.7,0,0.2],[0.5,0,0.5]};
    s = containers.Map(nu_type,symb);
    yyaxis right
    for i = 1:length(exp_state)
        b = bar(i,sum(f1.n_events(f1.exp_state == exp_state(i))),'FaceAlpha',0.5);   
    end
    yyaxis left
    for i = 1:length(n_id)
        roi = f1(f1.roi_short_name == n_id(i),:);
        base = sum(roi.n_events(roi.exp_state == exp_state(1)));
        stim = sum(roi.n_events(roi.exp_state == exp_state(2)));
        post = sum(roi.n_events(roi.exp_state == exp_state(3)));
        
        r_type = unique(roi.roi_type);
        
        plot([base,stim, post],'LineStyle','-','Color',s(r_type),'Marker','o',...
            'MarkerSize',15)
        
    end
    xticks(ax4,1:3)
    
    if do_save
        filename = sprintf("/Volumes/GlyR/GlyR project/Plots/FoVs/IVM/fov_summary_%s",...
            fovs(f));
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
    end
end
end