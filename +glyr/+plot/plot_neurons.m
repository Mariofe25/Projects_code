function plot_neurons(ts)

rois = begonia.processing.roi.load_processed_signals(ts);
try rois.metadata =[]; catch,end
ns_dnt = ts.load_var('donut_dff');

var_names = {'rois', 'roi_type'};
ns_rois = rois(rois.type == "NS",:);
ns_raw = ns_rois(:,{'signal_dff','type'});
ns_raw.Properties.VariableNames = var_names;
ns_sub = ns_rois(:, {'signal_subtracted_dff','type'});
ns_sub.Properties.VariableNames = var_names;
np_rois =  rois(rois.type == "Np",:);
np = np_rois(:,{'signal_dff','type'});
np.Properties.VariableNames = var_names;
ns_dnt = table(ns_dnt.signal_donut_dff,repmat("NS-dnt",height(ns_dnt),1));
ns_dnt.Properties.VariableNames = var_names;

neu_raw = [ns_raw;np];
neu_p = [ns_sub;ns_dnt];

neu_types =  unique(neu_raw.roi_type,"stable");
neu_type_start = arrayfun(@(tp) find(neu_raw.roi_type == tp, 1, 'first'), neu_types);

neu_p_types = unique(neu_p.roi_type,"stable");
neu_p_start = arrayfun(@(tp) find(neu_p.roi_type == tp, 1, 'first'), neu_p_types);
% plot figure:
fig = figure("color", [0.84,0.90,0.95], "Name", "Signal overview " + ts.name);
layout = tiledlayout(2, 1, "tilespacing", "compact");

colormap(begonia.colormaps.magma);

ax1 = nexttile();
imagesc(cell2mat(neu_raw.rois));
title("Neurons raw (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(neu_type_start); yticklabels(neu_types);
axis tight

ax2 = nexttile();
imagesc(cell2mat(neu_p.rois));
title("Neurons p (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 0.7])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(neu_p_start); yticklabels(neu_p_types);
axis tight
%linkaxes([ax1, ax2])
end







