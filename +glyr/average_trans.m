% average transitions
trans = unique(tab_r.trans_id,'stable');
out = nan(length(trans),270);
for j = 1:length(trans)
    tr = tab_r(tab_r.trans_id == trans(j),:);
    nrois(j) = height(tr);
    na_rois(j) = sum(tr.total_events > 0);
    valid_trans = sum(tr.total_events > 0) > 2;
    if valid_trans
        trcs = tr.trans;
        traces = horzcat(trcs{:})';
        avg_trace = mean(traces,'omitnan');
        if length(avg_trace) < 270
            out(j,1:length(avg_trace)) = avg_trace;
        else
            out(j,:) = avg_trace(1:270);
        end
    end
end


matx = nan(height(tab_r),270);
for i = 1:height(tab_r)
    if length(tab_r.trans{i}) < 270
        yy = 1:length(tab_r.trans{i});
    else
        yy = 1:tr_dur;
    end
    matx(i,yy) = tab_r.trans{i}(yy);
end
