function [h_b,h_s] = heatmap_align2loc(tss,baseline,stimulation,types)
% roi traces align to onset
if nargin == 1
    tab = glyr.merge_fov_rois(tss);
    [baseline,stimulation,types] = glyr.align_roi_type(tab);
end

%heatmaps
h_b = cell(1,6);
h_s = cell(1,6);
for i = 1:numel(types)
    h_b{i} = plot_it(baseline{i},types{i},"Baseline");
    h_s{i} = plot_it(stimulation{i},types{i},"Stimulation");
end
end

function fig = plot_it(traces,type,exp_state)
idx = all(isnan(traces'));
t = traces(~idx,:);
% sort by highest ∆F/F
[~,I] = sort(mean(t,2,'omitnan'),'descend');
fig = figure;
imagesc(t(I,:))
caxis([0,0.5])
colormap(begonia.colormaps.magma);
colorbar
xlabel('frames')
ylabel('n RoIs')
title(type + " traces align to locomotion onset. " + exp_state)
hold on
xline(30,'LineWidth',2,'LineStyle','--','Color','w')
hold off
end