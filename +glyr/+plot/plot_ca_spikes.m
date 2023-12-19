
ntss = 1:length(tss);
ts_idx = ntss(randperm(numel(ntss),25));

tns = tss(ts_idx);

for ts = tns

mtab = ts.load_var('multitab');
spikes = ts.load_var('Spike_prob');
ns = mtab(mtab.roi_type == "NS" & mtab.category == "spikes_prob",:);
sp = horzcat(ns.trace{:});

idx = ismember(spikes.roi_id,ns.roi_id);



dff = ts.load_var("roi_signals_dff_subtracted");
dff = dff(idx,:);

spikes = spikes(idx,:);



fig = figure("Position", [1000 305 1407 1032]);
traces = 1:height(dff);
idx = traces(randperm(numel(traces),10));
for i = 1:length(idx)
subplot(5,2,i)
plot(smooth(dff.signal_subtracted_dff{i}))
hold on
ss = spikes.signal_spikes{i};

ss(ss > 0.2) = ss(ss > 0.2) + 0.25;
plot(ss - 0.5,'LineWidth',2)
hold off
xlim tight
end


sgtitle("Ca2+ trace & spike porbability") 

path = "/Volumes/GlyR/GlyR project/Plots/Spike_prob";
filename = fullfile(path,ts.name + "_spike-prob_noise");
print(fig,filename,'-r300', '-dpng');
end