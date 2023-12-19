function plot_rois_by_channel(ts)
rois = begonia.processing.roi.load_processed_signals(ts);
try rois.metadata =[]; catch,end
ns_dnt = ts.load_var('donut_dff');

% for uncaging experiments, sort rois by type and distance to the shot
if ts.has_var('rois_target')
shot_distance = ts.load_var('rois_target');
% shot_distance = sortrows(shot_distance,{'type','shot_distance'});
rois = join(rois,shot_distance);
% rois w/ shot (title)
roi_w_shot = rois.type(rois.uncaging_category == "target" & rois.channel == 1);
if isempty(roi_w_shot)
    roi_w_shot  = "none";
end
ti = sprintf(ts.name +  "\n" + " Sorted by distance to shot. " + ...
      "Uncaging ROI(s): " + roi_w_shot);


% ns_dnt.shot_distnace = rois.shot_distance(rois.type == "NS");
% ns_dnt = sortrows(ns_dnt,'shot_distnace');  
end

% Remove signal from shot
[rois,ns_dnt] = Pac.uncaging.remove_shot_signal(ts,rois,ns_dnt);

var_names = {'rois', 'roi_type'};
ast_rois = rois(rois.channel == 1,:);
ast = ast_rois(:, {'signal_dff','type'});
ast.Properties.VariableNames = var_names;
ast = sortrows(ast,'roi_type');
ns_rois = rois(rois.type == "NS",:);
ns = ns_rois(:, {'signal_subtracted_dff','type'});
ns.Properties.VariableNames = var_names;
np_rois =  rois(rois.type == "Np",:);
np = np_rois(:,{'signal_dff','type'});
np.Properties.VariableNames = var_names;
ns_dnt = table(ns_dnt.signal_donut_dff,repmat("NS-dnt",height(ns_dnt),1));
ns_dnt.Properties.VariableNames = var_names;
neu = [ns;ns_dnt;np];

ast_types = unique(ast.roi_type);
ast_type_start = arrayfun(@(tp) find(ast.roi_type == tp, 1, 'first'), ast_types);

neu_types =  unique(neu.roi_type,"stable");
neu_type_start = arrayfun(@(tp) find(neu.roi_type == tp, 1, 'first'), neu_types);

% plot figure:
fig = figure("color", [0.84,0.90,0.95], "Name", "Signal overview " + ts.name);
layout = tiledlayout(2, 1, "tilespacing", "compact");
if ts.has_var('rois_target')
    title(layout,ti);
else
    title(layout,ts.name);
end
colormap(begonia.colormaps.magma);

ax1 = nexttile();
imagesc(cell2mat(ast.rois));
title("Astrocytes (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 2])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(ast_type_start); yticklabels(ast_types);
axis tight

ax2 = nexttile();
imagesc(cell2mat(neu.rois));
title("Neurons (df/f0)"); xlabel("Frame (#)"); colorbar();
%caxis([0 0.7])
%         if nargin > 1
%             caxis(dff_lims);
%         end
yticks(neu_type_start); yticklabels(neu_types);
axis tight
%linkaxes([ax1, ax2])
end