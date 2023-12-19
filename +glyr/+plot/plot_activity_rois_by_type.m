function fig_1 = plot_activity_rois_by_type(tss,do_save,format,not_donut)

if nargin < 4, not_donut = false; end
if nargin < 3, format = '-dpng'; end
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
    ast_rois = rois(startsWith(rois.roi_type,"A"),:);
    ns_rois = rois(startsWith(rois.roi_type,"N"),:);
    if not_donut        
        ns_rois(ns_rois.roi_type == "NS-dnt",:) = [];
    end
    rois = [ast_rois;ns_rois];

    % plot
    fig_1 = plot_it(ts,entity,dt,rois);
    
    if do_save      
        filename_signal = entity + "_Activity_RoIs signal" ;
        outpng_1 = fullfile(path, [char(filename_signal)]);
        print(fig_1, outpng_1, '-r300',format);
        % clean up:
        delete(fig_1)
    end
end
end

function fig = plot_it(ts,entity,dt,rois)
import begonia.util.*;

rois_t = unique(rois.roi_type,'stable');
total_heats = numel(rois_t);

% plot figure:
fig = figure("Position",[850 1 1102 1336],"color", [0.84,0.90,0.95],...
    "name", "Signal overview " + entity);
layout = tiledlayout(total_heats + 1, 1, "tilespacing", "compact");
title(layout,entity);

nexttile();
glyr.plot.plot_behaviour(ts,false,false)
% glyr.plot.plot_activity_state(ts,true,false)

for i = 1:total_heats
nexttile();
r = rois.rois(rois.roi_type == rois_t(i)); 
imagesc([r{:}]');

colorbar();
if startsWith(rois_t(i),"A")
    caxis([-0.05 2.05])
    ax = gca;
    colormap(ax,begonia.colormaps.magma);
else
    caxis([-0.05 1.05])
    ax = gca;
    colormap(ax,'parula')  
end
title(rois_t(i) + " (df/f0)");% xlabel("Frame (#)"); 
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
 xticks(300:300:unique(cellfun(@length,r))); 
 xticklabels(xticks*dt);
% axis tight
% ax3.XTickLabel = round(double(string(ax3.XTickLabel)) * dt,1);
end
%linkaxes([ax1, ax2])
end