function plot_activity_rois(tss,do_save,format)
if nargin < 3, format = 'png'; end
if nargin < 2, do_save = false; end

if do_save, path = uigetdir; end

for ts = tss 
    if ~ts.has_var("multitab")
        error(ts.name + " has not multitab available")    
    else
    ts_mtab = ts.load_var("multitab");
    end
    entity = unique(ts_mtab.entity);
    dt = unique(ts_mtab.trace_dt);
    
    %rois
    rois = ts_mtab.trace(ts_mtab.category == "ca-roi-dff");
    roi_type = ts_mtab.roi_type(ts_mtab.category == "ca-roi-dff");
    rois = table(rois,roi_type);
    rois = sortrows(rois,"roi_type");
    ast_rois = rois(rois.roi_type ~= "NS" & rois.roi_type ~= "Np" & rois.roi_type ~= "NS-dnt",:);
    ns_rois = rois(startsWith(rois.roi_type,"N"),:);

    % plot
    fig_1 = plot_it(ts,entity,dt,ast_rois,ns_rois);
    
    if do_save      
        filename_signal = entity + "_Activity_RoIs signal" ;
        outpng_1 = fullfile(path, [char(filename_signal),'.',format]);
        print(fig_1, outpng_1, '-r300',['-d',format]);
        % clean up:
        delete(fig_1)
    end
end
end

function fig = plot_it(ts,entity,dt,ast_rois,ns_rois)
import begonia.util.*;

ast_types = unique(ast_rois.roi_type);
ast_type_start = arrayfun(@(tp) find(ast_rois.roi_type == tp, 1, 'first'), ast_types);

ns_types =  unique(ns_rois.roi_type,"stable");
ns_type_start = arrayfun(@(tp) find(ns_rois.roi_type == tp, 1, 'first'), ns_types);

% plot figure:
fig = figure("Position",[1000 379 1140 958],"color", [0.84,0.90,0.95],...
    "name", "Signal overview " + entity);
layout = tiledlayout(3, 1, "tilespacing", "compact");
title(layout,entity);
colormap(begonia.colormaps.magma);

ax1 = nexttile();
glyr.plot.plot_behaviour(ts,false,false)
% glyr.plot.plot_activity_state(ts,true,false)

ax3 = nexttile();
imagesc([ast_rois.rois{:}]');
colormap(ax3,begonia.colormaps.magma);
colorbar();
caxis([-0.05 2.05])
title("Astrocytes (df/f0)");% xlabel("Frame (#)"); 
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(ast_type_start); yticklabels(ast_types);
axis tight
ax3.XTickLabel = round(double(string(ax3.XTickLabel)) * dt,1);

ax4 = nexttile();
imagesc([ns_rois.rois{:}]');
colormap(ax4,'parula');
colorbar();
caxis([-0.05 1.05])
title("Neurons (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(ns_type_start); yticklabels(ns_types);
xlabel("Time (sec)")
axis tight
ax4.XTickLabel = round(double(string(ax4.XTickLabel)) * dt,1);

%linkaxes([ax1, ax2])
end