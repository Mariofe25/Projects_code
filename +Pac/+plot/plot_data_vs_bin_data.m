function fig_1 = plot_data_vs_bin_data(tss,do_save)
if nargin < 2, do_save = true; end
if do_save,path = uigetdir; end
for ts = tss
    ts_mtab = ts.load_var('multitab');
    ts_mtab(ts_mtab.category == "locomotion",:) = [];
    entity = ts_mtab.entity(1);
    
    % Locomotion
    wheel = ts_mtab.trace{ts_mtab.category == "speed"};
    
    % Binarize data
    bin_wheel = ts_mtab.trace{ts_mtab.category == "running"};
    bin_whisker = ts_mtab.trace{ts_mtab.category == "whisking"};
    bin_ca = ts_mtab(ts_mtab.category == "ca_events",{'trace','roi_type'});
    
    % eliminate shot from traces (high dff/f)
    % (camera data: rois & whisker)
    if ts.has_var('uncaging_info')
        try
            uncaging = ts.load_var('uncaging_info');
            un_start = uncaging.Start;
            un_end = uncaging.End;
            uncage = un_start-2:un_end + 2;
            traces = [ts_mtab.trace{:}];
            traces(uncage,:) = hampel(traces(uncage,:));
            traces = num2cell(traces,1)';
            ts_mtab.trace = traces;
        catch
        end
    end
    
    % whisker
    whisker = ts_mtab.trace{ts_mtab.category == "whisker"};
    
    % rois
    rois = ts_mtab(ts_mtab.category == "ca-roi-dff",{'trace','roi_type'});
    %     roi_type = ts_mtab.roi_type(ts_mtab.category == "ca-roi-dff");
    %     rois = table(rois,roi_type);
    %     rois = sortrows(rois,"roi_type");
    %     ast_rois = rois(rois.roi_type ~= "NS" & rois.roi_type ~= "Np",:);
    %     ns_rois = ts_mtab.trace(ts_mtab.category == "ns-roi-dff");
    %     var_names = {'rois', 'roi_type'};
    %     ns_rois = table(ns_rois,roi_type,'VariableNames',var_names);
    %     ns_rois = ns_rois(ns_rois.roi_type == "NS",:);
    %     np_rois = rois(rois.roi_type == "Np",:);
    %     ns_dnt = ts_mtab.trace(ts_mtab.category == "np-roi-dff");
    %     ns_dnt = table(ns_dnt,repmat("Ns-dnt",length(ns_dnt),1),'VariableNames',var_names);
    %     neu_rois = [ns_rois;ns_dnt;np_rois];
    %     rois = [ast_rois;neu_rois];
    if ts.has_var('rois_target')
        shot_distance = ts.load_var('rois_target');
        % rois w/ shot (title)
        roi_w_shot =  shot_distance.type(shot_distance.uncaging_category == "target" & shot_distance.channel == 1);
        if isempty(roi_w_shot)
            roi_w_shot  = "none";
        end
        ti = sprintf(entity + "   Uncaging ROI(s): " + roi_w_shot(1));
    else
        ti = sprintf(entity);
    end
    
    % plot
    fig_1 = plot_it(ts_mtab, entity,wheel,whisker,rois,bin_wheel,bin_whisker,bin_ca,ti);
    if do_save
        filename_signal = entity + "_Activity & RoIs signal" ;
        outpng = fullfile(path, [char(filename_signal) '.png']);
        print(fig_1, outpng, '-r300', '-dpng');
        
        % clean up:
        delete(fig_1)
    end
end
end

function fig = plot_it(ts_mtab,entity,wheel,whisker,rois,bin_wheel,bin_whisker,bin_ca,ti)
import begonia.util.*;

rois = sortrows(rois, "roi_type");
bin_ca = sortrows(bin_ca,"roi_type");

types = unique(rois.roi_type);
type_start = arrayfun(@(tp) find(rois.roi_type == tp, 1, 'first'), types);

bin_types = unique(bin_ca.roi_type);
bin_type_start = arrayfun(@(tp) find(bin_ca.roi_type == tp, 1, 'first'), bin_types);

% plot figure:
fig = figure("color", [0.84,0.90,0.95], "name", "Signal overview " + entity);
fig.Position = [745,184,891,867];
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
imagesc([rois.trace{:}]');
colormap(ax3,begonia.colormaps.magma);
title("ROIs (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(type_start); yticklabels(types);
axis tight

ax4 = nexttile();
imagesc([bin_ca.trace{:}]');
colormap(ax4,begonia.colormaps.magma);
title("ROIs Ca2+ events"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(bin_type_start ); yticklabels(bin_types);
axis tight
%linkaxes([ax1, ax2, ax3])
end