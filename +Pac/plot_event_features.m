function plot_event_features(mtab,do_save)

import begonia.logging.log
% genotype (for saving table and figure)
gen = unique(string(mtab.genotype));

% get rid of some roi types and spikes
mtab(mtab.roi_type == "ND",:) = [];
mtab(mtab.category == "spikes_prob",:) = [];
mtab(cellfun(@isempty,mtab.events),:) = [];

% Colors rois
Pac.plot.roi_type_colors;

% Figure for boxplots
fig1 = figure('Position',[520 30 1533 1307],'Name',...
    "Events AUC " + gen);
l1 = tiledlayout(2,4,'TileSpacing','compact');
title(l1,"Events AUC")

% nrois
fig2 = figure('Position',[520 30 1533 1307],'Name',...
    "Events Half-Width " + gen);
l2 = tiledlayout(2,4,'TileSpacing','compact');
title(l2,"Events Half-Width")

% nrois by mouse
fig3 = figure('Position',[520 30 1533 1307],'Name',...
    "Events Duration " + gen);
l3 = tiledlayout(2,4,'TileSpacing','compact');
title(l3,"Events Duration")

% nrois
fig4 = figure('Position',[520 30 1533 1307],'Name',...
    "Events Prominence " + gen);
l4 = tiledlayout(2,4,'TileSpacing','compact');
title(l4,"Events Prominence")

% nrois by mouse
fig5 = figure('Position',[520 30 1533 1307],'Name',...
    "Events Amplitude " + gen);
l5 = tiledlayout(2,4,'TileSpacing','compact');
title(l5,"Events Amplitude")

% Get mtab by roi type
roi_types = unique(mtab.roi_type);
for i = 1:length(roi_types)
    tab = mtab(mtab.roi_type == roi_types(i),:);
    events = [tab.events{:}];
    nevents = cellfun(@length,tab.events);
    behavs = repelem(string(tab.seg_category),nevents);
    auc = [events.auc]';
    width_half = [events.width_half]'/10;
    width = [events.width]';
    prom = [events.prominance]';
    amp = [events.y]';
    nexttile(l1,i)
    boxchart(categorical(behavs),auc,'BoxFaceColor',...
        roi_colors(roi_types(i)),"MarkerColor",roi_colors(roi_types(i)));
    title(roi_types(i))
    ylabel("∆F/F.sec-1")
    nexttile(l2,i)
    boxchart(categorical(behavs),width_half,"BoxFaceColor",...
        roi_colors(roi_types(i)),"MarkerColor",roi_colors(roi_types(i)));
    title(roi_types(i))
    ylabel("Time (sec)")
    nexttile(l3,i)
    boxchart(categorical(behavs),width,"BoxFaceColor",...
        roi_colors(roi_types(i)),"MarkerColor",roi_colors(roi_types(i)));
    title(roi_types(i))
    ylabel("Time (sec)")
    nexttile(l4,i)
    boxchart(categorical(behavs),prom,"BoxFaceColor",...
        roi_colors(roi_types(i)),"MarkerColor",roi_colors(roi_types(i)));
    title(roi_types(i))
    ylabel("∆F/F")
    nexttile(l5,i)
    boxchart(categorical(behavs),amp,"BoxFaceColor",...
        roi_colors(roi_types(i)),"MarkerColor",roi_colors(roi_types(i)));
    title(roi_types(i))
    ylabel("∆F/F")
end


if do_save
    figs = [fig1,fig2,fig3,fig4,fig5];
    log(1,"Saving plots")
    p = "/Volumes/Xiaoyi1/PAC/Analysis/Events_features";
    p = sprintf('%s/%s',p,gen);
    for i = 1:length(figs)
        f = figs(i).Name;
        filename = fullfile(p,f);
        begonia.path.make_dirs(filename);
        print(figs(i),filename,'-r300', '-dpng');
        delete(figs(i)) 
    end
end
end