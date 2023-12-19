%% Plot rois heatmaps and wheel trace
function plot_traces(trials)
    
for i = 1:length(trials)
f = figure();
f.Color = 'w';
sgtitle(string(trials{i}.group_id(1)));
time = (trials{i}.delta_time(1)*(1:length(trials{i}.trace{1})))';


% Wheel
subplot(3,1,1)
wheel_trace = (trials{i}.trace(trials{i}.category == "wheel"));
plot(wheel_trace{:},'k')

if ~isempty(trials{i}.airpuff(1))
    hold on
    xline(trials{i}.airpuff(1),'r')
    hold off
end

title('wheel data')
ylabel('d/s')
xx = xticks;
xx(1) = 1;
xx(end) = [];
xticklabels(round(xax(xx)))
xlabel('s')
xlim([0 length(xax)])

% if ~isempty(trials{i}.trace(trials{i}.roi_channel == '1'))
% astrocytes
subplot(3,1,2)
roi_traces = trials{i}.trace(trials{i}.roi_channel == '1');
imagesc(horzcat(roi_traces{:})');
title('Astrocytes RoI signals over time (df/f_0)');
colormap(begonia.colormaps.magma)
caxis([0 0.2])
ylabel('RoI (#)');
xticks(xx)
xticklabels(round(xax(xx)))
xlabel('s','HorizontalAlignment','right')

% neurons
subplot(3,1,3)
roi_traces = trials{i}.trace(trials{i}.roi_channel == '2');
imagesc(horzcat(roi_traces{:})');
title('Neurons RoI signals over time (df/f_0)');
colormap(begonia.colormaps.magma)
caxis([0 0.2])
ylabel('RoI (#)');
xticks(xx)
xticklabels(round(xax(xx)))
xlabel('s','HorizontalAlignment','right')

% xlim([0 xax(end)])


% hold on
% line([1,100],[20,20],'Color','w','LineWidth',1)
% hold off
% end

end
end