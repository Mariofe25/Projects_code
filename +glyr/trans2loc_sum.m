rois_type = ["AE","AP","AS","NS","NS-dnt","Np"];
dt = 0.25;
time_bins = -3:0.25:max(tab.trans_length)/fs + 1;
for i = 1:length(rois_type)

    % table rois type i
    trans = events(rois_type(i));
    time_bins = -3:0.25:double(string(trans.Properties.VariableNames{end}));
    time_idx = 7:length(time_bins)+ 6;

    % total number transitions
    total_trans(i) = height(trans);

    % total numebr transitions w/ more than 6s
    for j = 1:height(trans)
        idx(j,1) = find(ismissing(trans(j,:)),1);
    end

    loc_time = time_bins(idx-7);

    trans.loc_time = loc_time';
    trans = movevars(trans,'loc_time','After','active');

    total_trans_6ps = sum(trans.loc_time >= 6);

    trans_nope = sum(trans.active <=3);
    ratio_nope_trans(i) = trans_nope/total_trans(i);
    ratio_active_trans(i) = 1 - ratio_nope_trans(i);

    active_rois_total(i) = trans.active./trans.nrois;

    trans_filt = trans(trans.active >=1,:);

    % rate active rois of trans with >= 3 active rois
    active_rois_filt(i) = trans_filt.active./trans_filt.nrois;

end


