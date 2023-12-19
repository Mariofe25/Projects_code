function plot_activity_rois(mtab, do_uncaging, do_save)
if nargin < 3, do_save = false; end
if nargin < 2, do_uncaging = false; end
if do_save
    path = uigetdir; %'/Volumes/Xiaoyi2/Plots';
end
ts_groups = unique(mtab.entity);
for i = 1:length(ts_groups)
    ts_mtab = mtab(mtab.entity == ts_groups(i),:);
    entity = ts_groups(i);
    dt = unique(ts_mtab.trace_dt);
    
    % wheel
    try
        wheel = ts_mtab.trace{ts_mtab.category == "speed"};
        run  = ts_mtab.trace{ts_mtab.category == "running"};
    catch
        wheel = ts_mtab.trace{ts_mtab.category == "wheel"};
    end
    
    
    % eliminate shot from traces (high dff/f)
    % (camera data: rois & whisker)
    if do_uncaging
        traces = [ts_mtab.trace{:}];
        traces(390:405,:) = 0;
        traces = num2cell(traces,1)';
        ts_mtab.trace = traces;
    end
    
    % whisker
    whisker = ts_mtab.trace{ts_mtab.category == "whisker"};
    whisking = ts_mtab.trace{ts_mtab.category == "whisking"};
    
    % rois
    rois = ts_mtab.trace(ts_mtab.category == "ca-roi-dff");
    roi_type = ts_mtab.roi_type(ts_mtab.category == "ca-roi-dff");
    rois = table(rois,roi_type);
    rois = sortrows(rois,"roi_type");
    ast_rois = rois(rois.roi_type ~= "NS" & rois.roi_type ~= "Np" & rois.roi_type ~= "NS-dnt",:);
    ns_rois = rois(startsWith(rois.roi_type,"N"),:);
%     var_names = {'rois', 'roi_type'};
%     ns_rois = table(ns_rois,roi_type,'VariableNames',var_names);
%     ns_rois = ns_rois(ns_rois.roi_type == "NS",:);
%     np_rois = rois(rois.roi_type == "Np",:);
%     ns_dnt = ts_mtab.trace(ts_mtab.category == "np-roi-dff");
%     ns_dnt = table(ns_dnt,repmat("Ns-dnt",length(ns_dnt),1),'VariableNames',var_names);
%     neu_rois = [ns_rois;ns_dnt;np_rois]; 
    
    % plot
    fig_1 = plot_it(entity,dt,wheel,run,whisker,whisking,ast_rois,ns_rois);
    
    if do_save
        filename_signal = entity + "_Activity & RoIs signal" ;
        outpng_1 = fullfile(path, [char(filename_signal) '.png']);
        print(fig_1, outpng_1, '-r300', '-dpng');
        % clean up:
        delete(fig_1)
    end
    
end
end

function fig = plot_it(entity,dt,wheel,run,whisker,whisking,ast_rois,ns_rois)
import begonia.util.*;

ast_types = unique(ast_rois.roi_type);
ast_type_start = arrayfun(@(tp) find(ast_rois.roi_type == tp, 1, 'first'), ast_types);

ns_types =  unique(ns_rois.roi_type,"stable");
ns_type_start = arrayfun(@(tp) find(ns_rois.roi_type == tp, 1, 'first'), ns_types);

% plot figure:
fig = figure("color", [0.84,0.90,0.95], "name", "Signal overview " + entity);
layout = tiledlayout(4, 1, "tilespacing", "compact");
title(layout,entity);
colormap(begonia.colormaps.magma);

ax1 = nexttile();
yyaxis left
plot(wheel,'Color',[0.3 0.3 0.3])
ylabel("Deg/sec")
grid on
yyaxis right
plot(run)
ylabel("Running status")
title("Locomotion"); %xlabel("Frame (#)");
axis tight
yl = double(string(ax1.XTickLabel)) * dt;
ax1.XTickLabel = round(yl,1);


ax2 = nexttile();
yyaxis left
plot(whisker,'Color',[0.3 0.3 0.3])
ylabel("Pixel change")
grid on
yyaxis right
plot(whisking)
ylabel("Whisking status")
title("Whisking");% xlabel("Frame (#)");
axis tight
ax2.XTickLabel = round(yl,1);


ax3 = nexttile();
imagesc([ast_rois.rois{:}]');
title("Astrocytes (df/f0)");% xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(ast_type_start); yticklabels(ast_types);
axis tight
ax3.XTickLabel = round(yl,1);

ax4 = nexttile();
imagesc([ns_rois.rois{:}]');
title("Neurons (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(ns_type_start); yticklabels(ns_types);
xlabel("sec")
axis tight
ax4.XTickLabel = round(yl,1);
%linkaxes([ax1, ax2])
end