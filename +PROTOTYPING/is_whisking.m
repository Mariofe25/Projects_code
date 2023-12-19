function  whisking =  is_whisking(mtab,data)
idx = cellfun(@isempty,data);
data(idx) = [];

CAT_OTHER = categorical("other");
CAT_WHISK = categorical("whisk");

for i = 1:length(data)
    
    whisker = data{i}.trace(data{i}.category == "whisker");
    whisk_trace = whisker{:};
    
    % smooth, find baseline and classify:
    whisk_trace = movmean(whisk_trace, 10);
    baseline = mode(whisk_trace);
    whisking = (whisk_trace - baseline) > 1.5; % from Daniel / Klas / slee project
    
    whisk_cat = repmat(CAT_OTHER, length(whisk_trace), 1);
    whisk_cat(whisking) = CAT_WHISK;
    
    trace = whisking;
    
    dt = unique(data{i}.delta_time);
    group_id = unique(data{i}.group_id);
    data_id = "bh_whisk-" + string(group_id);
    category = "binarized_whisker";
    
    mtab.update(trace,data_id, group_id, category,"", "binarize", dt);
    mtab.save();
end
end