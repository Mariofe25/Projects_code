function plot_spike_probablity_bybehav(mtab,do_save)
if nargin < 2, do_save = true; end

gen = unique(string(mtab.genotype));
fs = 1/unique(mtab.trace_dt);

% get spikes
spikes = mtab(mtab.category == "spikes_prob" & mtab.roi_type == "NS",:);
ss = spikes.trace;
bb = spikes.seg_category;

% Number of naan on each trace
na = num2cell(cellfun(@(s) sum(isnan(s)),ss),2);

% find number of spikes with a probabilty > thr
thr = 0.3;
warning off
n = cellfun(@(s,g) numel(findpeaks(s,"MinPeakHeight",thr))/((length(s)-g)/fs),...
    spikes.trace,na);

% spikes per second in each trace. Consider number onf nans to remove from
% trace (recaulate duraion)
sum_ss = cellfun(@(s,g) (sum(s,'omitnan')/(length(s)-g))*fs,ss,na);
spikes.total_spikes = sum_ss;
spikes(isnan(spikes.total_spikes),:) = [];
sum_ss(isnan(sum_ss)) = [];


%% Plot
fig = figure("Position",[260 160 1238 937]);
layout = tiledlayout(2,4,"TileSpacing","compact");
nexttile(layout,1,[1,2])
boxchart(spikes.seg_category,sum_ss)
title("Spike probability")
ylabel("Spikes rate/sec")

nexttile(layout,3,[1,2])
boxchart(bb,n)
title("n Spike probabilty > " + thr)
ylabel("n spikes/sec")

behavs = unique(spikes.seg_category);
behavs(behavs== "Still") = [];
rois = unique(spikes.roi_id);
for j = 1: numel(behavs)
    for i = 1:numel(rois)
        roi = spikes(spikes.roi_id == rois(i),:);
        try
            still(i) = roi.total_spikes(roi.seg_category == "Still");
            behv(i) = roi.total_spikes(roi.seg_category == behavs(j));
        catch
            still(i) = nan;
            behv(i) = nan;
        end
    end

    still(isnan(still)) = [];
    behv(isnan(behv)) = [];

    rate = round(behv'./still',2);

    % increase at least 10%
    incr = sum(rate > 1.25)/length(rate);
    nochg = sum(rate < 1.25 & rate > 0.75)/length(rate);
    dcr = sum(rate < 0.75)/length(rate);

    nexttile(layout,4+j)
    bar([incr,nochg,dcr])
    title("Still vs. " + string(behavs(j)))
    xticklabels(["Increase", "No change" ,"Decrease"])
    ylabel("10% change")

    % clean up
    still = [];
    run = [];
end

%% Save figure
if do_save
    p = "/Volumes/Xiaoyi1/PAC/Analysis/Spike_probability";
    f1 = gen + "_Spike_probability_behaviour_state";
    filename = fullfile(p,f1);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-dpng');
    delete(fig)
end
end