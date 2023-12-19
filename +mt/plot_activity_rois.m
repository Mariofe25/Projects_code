%% plot/save activity & ca2+ signal
plots_folder = '/Volumes/Xiaoyi2/4mt/Plots';
if ~isfolder(plots_folder)
    mkdir(plots_folder)
end


for ts = tss
    try
    ts_mtab = ts.load_var('multitab');
    ts_mtab(ts_mtab.category == "locomotion",:) = [];
    entity = ts_mtab.entity(1);
    
    % Locomotion
    wheel = ts_mtab.trace{ts_mtab.category == "speed"};
    
    % Binarize data
    bin_wheel = ts_mtab.trace{ts_mtab.category == "running"};
    bin_whisker = ts_mtab.trace{ts_mtab.category == "whisking"};
    bin_ca = ts_mtab(ts_mtab.category == "ca_events",{'trace','roi_type'});
    
    % whisker
    whisker = ts_mtab.trace{ts_mtab.category == "whisker"};
    
    % rois
    rois = ts_mtab(ts_mtab.category == "ca-roi-dff",{'trace','roi_type'});
    ast_rois = rois(rois.roi_type ~= "NS" & rois.roi_type ~= "Np" & rois.roi_type ~= "NS-dnt",:);
    neu_rois = rois(rois.roi_type == "NS" | rois.roi_type == "Np" | rois.roi_type == "NS-dnt",:);
    
    % figure title
    ti = sprintf(entity);
    
    % plot
    fig = plot_it(ts_mtab, entity,wheel,whisker,ast_rois,neu_rois,bin_wheel,bin_whisker,ti);
    out_type = "Activity & RoIs signal";
    mt.save_plot(ts,plots_folder,fig, out_type)
    % clean up:
    delete(fig)
    catch err
        disp(err)
    end
    
end


function fig = plot_it(ts_mtab,entity,wheel,whisker,ast_rois,neu_rois,bin_wheel,bin_whisker,ti)
import begonia.util.*;

ast_rois = sortrows(ast_rois, "roi_type");
neu_rois = sortrows(neu_rois,"roi_type");

ast_types = unique(ast_rois.roi_type);
ast_type_start = arrayfun(@(tp) find(ast_rois.roi_type == tp, 1, 'first'), ast_types);

neu_types = unique(neu_rois.roi_type);
neu_type_start = arrayfun(@(tp) find(neu_rois.roi_type == tp, 1, 'first'), neu_types);

% plot figure:
fig = figure("color", [0.84,0.90,0.95], "name", "Signal overview " + entity);
% fig.Position = [745,184,891,867];
layout = tiledlayout(5, 1, "tilespacing", "compact");
title(layout,ti);

ax0 = nexttile();
Pac.plot.plot_activity_state(ts_mtab,false)

ax1 = nexttile();
yyaxis left
plot(wheel,'Color',[0.3 0.3 0.3])
grid on
title("Locomotion"); xlabel("Frame (#)");
ylabel("Deg/sec")

yyaxis right
plot(bin_wheel)
%ylim([0,1.5])
ylim([min(ax1.YLim),1.5])
set(gca, 'XLimSpec', 'Tight')
%axis tight

ax2 = nexttile();
yyaxis left
plot(whisker,'Color',[0.3 0.3 0.3])
grid on
title("Whisking"); xlabel("Frame (#)");
ylabel("Pixel change")

yyaxis right
plot(bin_whisker)
ylim([min(ax2.YLim),1.5])
set(gca, 'XLimSpec', 'Tight')
%axis tight

ax3 = nexttile();
imagesc([ast_rois.trace{:}]');
colormap(ax3,begonia.colormaps.magma);
title("Astrocytes RoIs (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(ast_type_start); yticklabels(ast_types);
axis tight

ax4 = nexttile();
imagesc([neu_rois.trace{:}]');
colormap(ax4,begonia.colormaps.magma);
title("Neuron RoIs (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(neu_type_start); yticklabels(neu_types);
axis tight
end