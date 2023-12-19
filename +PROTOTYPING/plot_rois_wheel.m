function plot_rois_wheel(rois,wheel,varargin)
fig = figure;
sgtitle(varargin)
subplot(3,1,1)
yucca.mod.wheel.plot_da_dist(wheel)
xlim([0, wheel.Time(end)])
% xticklabels(round(rois.dff_signals.Time(xticks)))

subplot(3,1,2)
astrocytes_idx = find(cell2mat({rois.roi_array.channel})== 1);
imagesc(rois.dff_signals.Data(:,astrocytes_idx)')
xticklabels(round(rois.dff_signals.Time(xticks)))
title('Astrocyte RoI signals over time (df/f_0)')
colormap(begonia.colormaps.magma);
colorbar
ylabel('RoI (#)')

subplot(3,1,3)
imagesc([rois.dff_signals_doughnut_subtracted.Data';...
    rois.dff_signals.Data(:,{rois.roi_array.group} == "Np")'])
xticklabels(round(rois.dff_signals.Time(xticks)))
title('NS & Np RoI signals over time (df/f_0)')
xlabel(['Time (' rois.dff_signals.TimeInfo.Units ')']);
ylabel('RoI (#)')
colormap(begonia.colormaps.magma);
colorbar

end

