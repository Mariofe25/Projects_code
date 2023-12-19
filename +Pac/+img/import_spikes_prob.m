function import_spikes_prob(tss,path,save_name)
if nargin < 3, save_name = "spike_prob"; end
if nargin < 2, path = "/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/spike_predicitions";end
begonia.logging.log(1,'Importing Spikes probabilities...')
r = 0;
tot = length(tss);
for ts = tss
    r = r + 1;
    begonia.logging.backwrite(1,'%d/%d',r,tot)
    name = ts.name;
    prdcs = dir(path);
    prdcs(startsWith(string({prdcs.name}),'.'),:) = [];
    prdcs_path = string(fullfile({prdcs.folder},{prdcs.name}))';
    rois = begonia.processing.roi.load_processed_signals(ts);
    idx = contains(prdcs_path,name);
    spikes = load(prdcs_path(idx)).spike_prob;
    if ts.has_var("Denoised") && ts.load_var("Denoised")
        durr = unique(cellfun(@length,rois.signal_raw));
        if length(spikes) + 60 == durr
            s = nan(size(spikes,1),durr);
            s(:,31:end-30) = spikes; 
            spikes = s;
        end
    end
    spikes = num2cell(spikes,2);
    signal_spikes = num2cell(nan(height(rois),...
        cellfun(@length,rois.signal_raw(1))),2);
    signal_spikes(rois.type == "NS") = spikes;
    roi_id = rois.roi_id;
    signal_spikes = table(roi_id,signal_spikes);
    ts.save_var(save_name,signal_spikes)
end
begonia.logging.log(1,'Done!')
end