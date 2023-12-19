function import_spikes_prob(tss,path,save_name)
if nargin < 3, save_name = "Spike_prob"; end
if nargin < 2, path = '/Volumes/GlyR/full_predictions';end
begonia.logging.log(1,'Importing Spikes probabilities...')
r = 0;
tot = length(tss);
for ts = tss
    r = r + 1;
    begonia.logging.backwrite(1,'%d/%d',r,tot)
    name = ts.name;
    prdcs = dir(path);
    prdcs_path = string(fullfile({prdcs.folder},{prdcs.name}))';
    idx = contains(prdcs_path,name);
    spikes = load(prdcs_path(idx)).spike_prob;
    spikes = num2cell(spikes,2);
    rois = begonia.processing.roi.load_processed_signals(ts);
    signal_spikes = num2cell(nan(height(rois),...
        cellfun(@length,rois.signal_raw(1))),2);
    signal_spikes(rois.type == "NS") = spikes;
    roi_id = rois.roi_id;
    signal_spikes = table(roi_id,signal_spikes);
    ts.save_var(save_name,signal_spikes)
end
begonia.logging.log(1,'Done!')
end