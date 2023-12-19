function roi_tab = merge_fov_rois(tss)
% grab the tables with the align traces. First step is to merge the same
% rois, present in different tseries (same fov). Second step is to average
% rois by type to later plot the average ± SD

tabs = tss.load_var("trans_tab");
if iscell(tabs)
    tabs = vertcat(tabs{:});
end
rois = unique(tabs.name);

for i = 1:length(rois)
    roi = tabs(tabs.name == rois(i),:);
    roi_id(i,1) = unique(roi.name);
    roi_type(i,1) = unique(roi.type);
    base_before{i,1}= mean_merge(roi.base_before);
    base_after{i,1} = mean_merge(roi.base_after);
    stim_before{i,1} = mean_merge(roi.stim_before);
    stim_after{i,1} = mean_merge(roi.stim_after);
end
roi_tab = table(roi_id,roi_type,base_before,base_after,stim_before,stim_after);
end

function merge = mean_merge(traces)
s = unique(cellfun(@length,traces),'stable');
[maxx,in] = max(s);
if numel(s) > 1
    for c = 1:length(traces)
        ll = cellfun(@length,traces(c));
        if ll == in, continue;end        
        traces{c} = [nan(maxx - ll,1);traces{c}];
    end    
end

merge = horzcat(traces{:});
merge = mean(merge,2,'omitnan');
end