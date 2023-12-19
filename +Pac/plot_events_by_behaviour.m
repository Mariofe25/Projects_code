function tabs = plot_events_by_behaviour(mtab,do_save)
if nargin < 2, do_save = false; end

import begonia.logging.log
% genotype (for saving table and figure)
gen = unique(string(mtab.genotype));

% get rid of some roi types and spikes
mtab(mtab.roi_type == "ND",:) = [];
mtab(mtab.category == "spikes_prob",:) = [];

% Colors rois
Pac.plot.roi_type_colors;

% Figure for boxplots
fig1 = figure('Position',[520 30 1533 1307],'Name',...
    "Events frequency by behaviour state " + gen);
l1 = tiledlayout(2,4,'TileSpacing','compact');
title(l1,"Events frequency (min)")

% nrois
fig2 = figure('Position',[520 30 1533 1307],'Name',...
    "Active rois  " + gen);
l2 = tiledlayout(2,4,'TileSpacing','compact');
title(l2,"Active rois")

% nrois by mouse
fig3 = figure('Position',[520 30 1533 1307],'Name',...
    "Active rois by mouse. " + gen);
l3 = tiledlayout(2,4,'TileSpacing','compact');
title(l3,"Active rois by mouse")

% Get mtab by roi type
roi_types = unique(mtab.roi_type);
for i = 1:length(roi_types)
    nexttile(l1,i)
    tab = mtab(mtab.roi_type == roi_types(i),:);
    if isempty(tab), continue, end

    tab.n_events = cellfun(@(s) length(s),tab.events);
    tab.active_rois = tab.n_events > 0;

    % Get total number of rois (and active)
    tot_rois = numel(unique(tab.roi_id));
    rt = unique(tab.seg_category,'stable');
    nrois = histcounts(tab.seg_category);  
   
    % Get event frequency in secs and mins
    state_secs = tab.total_sec;
    events = tab.events;
    n_events = cellfun(@length,events);

    tab.n_events = n_events;
    tab.events_sec = n_events./state_secs;
    tab.events_min = tab.events_sec * 60;

    % mtab with active rois (rois with events)
    tab_a = tab(tab.active_rois > 0,:);
    rta = unique(tab_a.seg_category,'stable');
    anrois = histcounts(tab_a.seg_category);

    hold on
    warning off

    % plot roi type in all behaviours (rois with events)
    boxc = boxchart(tab_a.seg_category,tab_a.events_min,"BoxFaceColor",...
        roi_colors(roi_types(i)),"MarkerColor",roi_colors(roi_types(i)));
    title(roi_types(i),"Events frequency")
    ylabel("Events/min")
    warning on

    % number of active rois per behaviour state (general and by mouse)
    nexttile(l2,i)
    hold on
    bar(rt,nrois,'FaceColor',roi_colors(roi_types(i)),'FaceAlpha',0.45)
    b = bar(rt,anrois,'FaceColor',roi_colors(roi_types(i)));
    xtips = b.XEndPoints;
    ytips = b.YEndPoints;
    text(xtips,ytips,string(round(anrois./nrois,2)),'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    title(roi_types(i)," Rate active rois")
    ylabel("rate")

    nexttile(l3,i)
    hold on
    mice = unique(tab.mouse);
    for j = 1:length(mice)
        mnrois(j,:) = histcounts(tab.seg_category(tab.mouse == mice(j)));
        manrois(j,:) = histcounts(tab_a.seg_category(tab_a.mouse == mice(j)));
    end
    b2 = bar(rt,mnrois,'FaceAlpha',0.25);
    b3 = bar(rt,manrois,'FaceColor','flat');
    set(b3, {'FaceColor'}, num2cell(reshape([b2.FaceColor],3,[])',2));
    ylabel("n rois")
    title(roi_types(i) + " Rate active rois")
    if i == length(roi_types)
        leg = legend([b2,b3],[mice + " all"; mice + " active"]);
        leg.Position = [0.7455 0.3380 0.0528 0.1365];
    end

    % number of events in each behaviour state (general and by mouse)


    % change of roi event frequency. Still vs*

    % tables
    t = tab(:,{'mouse','seg_category','entity','channel','genotype',...
        'roi_type','roi_id','active_rois','n_events','events_sec',...
        'events_min','total_sec'});
    tabs{i} =  t;
end



if do_save
    log(1,"Saving plots")
    p = "/Volumes/Xiaoyi1/PAC/Analysis/Events_frequency";
    p = sprintf('%s/%s',p,gen);
    f1 = "Events frequency by behaviour state";
    f2 = "Ratio active rois";
    f3 = "Active rois by mouse";
    filename1 = fullfile(p,f1);
    filename2 = fullfile(p,f2);
    filename3 = fullfile(p,f3);

    begonia.path.make_dirs(filename1);
    begonia.path.make_dirs(filename2);
    begonia.path.make_dirs(filename3);
    print(fig1,filename1,'-r300', '-dpng');
    print(fig2,filename2,'-r300', '-dpng');
    print(fig3,filename3,'-r300', '-dpng');
    delete(fig1)
    delete(fig2)
    delete(fig3)
    log(1, "Saving tables")
    fname = fullfile(p,"tabs");
    for r = 1:length(roi_types)
        tabname = fullfile(fname,"Events_" + roi_types(r));
        begonia.path.make_dirs(tabname);
        writetable(tabs{r},tabname,'FileType','spreadsheet')
    end
end