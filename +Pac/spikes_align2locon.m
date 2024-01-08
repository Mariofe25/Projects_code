function spikes_align2locon(tss)
% Calculate neuronal spike probabilites in the different behaviours
% states. Instead of differencing Motion and Run, consider only locomotion.
% For this, identify transition to motion. This way each roi will have
% different transitions (deal with that later, randomly taking transitions
% or with bootstrap). The locomotion will be segmented by second to check
% if there is any difference, from 1 to the first 5 sec. The seconds after
% (extra) will be put together. The overall locomotion spike probabiliuty
% is also calculated. The Still segment is randomly taken. Still is
% segmented by second and then randomly taken up to 10 sec before each
% transition. Still segments are trimmed on both sides to avoid any
% influence of other behaviour states on  its spike probability. Also, and,
% since whisking detection is not very accurate, in the Still whisking
% category include some extra frames in the start and end (TBD: see if
% there is any difference inluding these extra frames in the Still Whisking
% category)
% TBD 2: deal with tseries withot transitions. (It can happen that the mouse
% is running at the beggining and there is not transition... or that the
% mouse is not moving at all. In this case, Still and Still Whisking can
% still (haha) be calculated.

% The spikes probabities are calculated by adding the spikes probs of the
% corresponding second/fragment of the trace obtained with Cascade. Maybe
% there are spikes, but porbabiity is diluted. Maybe it would be better to
% find numbre of spike probabilities higher than x% (e.g. 0.4) instead of
% adding spike probabities...

import begonia.logging.backwrite
r = 0;
rr = length(tss);
nnn = 0;
for ts = tss
    r = r + 1;
    backwrite(1,'Spike probabities for tseries: %d/%d',r,rr)
    m = ts.load_var("multitab_segmented");
    mtab = ts.load_var("multitab");
    ns = mtab(mtab.roi_type == "NS" & mtab.category == "spikes_prob",:);
    ns_ca = mtab(mtab.roi_type == "NS" & mtab.category == "ca-roi-dff",:);
    loc = mtab.trace{mtab.category == "locomotion"};
    times = unique(m(:,{'seg_start_f','seg_end_f','seg_category'}'));
    times = sortrows(times,'seg_start_f','ascend');
    times.seg_category = string( times.seg_category);
    fs = 1/unique(mtab.trace_dt);

    %% Whisking
    % take the still-whisking segments. In addition, to prevent "still"
    % contamination, take 0.5 sec before/after each still segment. Remove
    % these indices if found in the still final trace. Alos remove from
    % still-whisking indices that fall in the locomotion category
    swhisk = find(times.seg_category == "Transition_still_motion");umel(sw)

    for i = 1:numel(swhisk)
        sw = swhisk(i);
        if times.seg_start_f(sw) - 0.5*fs < 1
            sw_idx{i} = 1:times.seg_end_f(s) +0.5*fs;
        elseif times.seg_end(sw) + 0.5*fs > times.seg_end(end)
            sw_idx{i} = times.seg_start_f(sw) - 0.5*fs:times.seg_end(end);
        else
            sw_idx{i} = times.seg_start_f(sw) - 0.5*fs:times.seg_end_f(s) +0.5*fs;
        end
    end

    % Still whisking indices. Use it to filter still. Also remove possible
    % locomotion indices (this is done after getting the other categories
    % indices)
    swhisk_idx = [sw_idx{:}];


    %% Find transitions
    % transition to locomotion
    trans_idx = find(times.seg_category == "Transition_still_motion");

    if isempty(trans_idx) % TBD 2
        % no transitions to locomotion. But overall still, still whisking 
        % and locomotion can be calculated
        disp(r)
        continue
    end

    % Still
    still_idx = find(times.seg_category == "Still");

    % Locomotion
    locomotion_idx = trans_idx + 1;

    % Locomotion can be Motion or Run. Sometimes it starts as Motion, with
    % less than 2 sec. Check if next segement(s) is Run/Motion. If so, include it in
    % the locomotion segment

    loc_end_idx = locomotion_idx;
    for i = 1:length(trans_idx)
        n = 0;
        cat = string(times.seg_category(locomotion_idx(i))); % Initialize cat for each iteration
        while ~(strcmp(cat, "Still") || strcmp(cat, "Still-Whisking"))
            n = n + 1;
            if locomotion_idx(i) + n > height(times)
                break
            end
            cat = times.seg_category(locomotion_idx(i) + n);
        end
        loc_end_idx(i) = locomotion_idx(i)+ n -1;
    end
    % if length(trans_idx) > 1
    %     locs_tim = find(times.seg_category ~= "Run" & times.seg_category ~="Motion");
    %     loc_end_idx = arrayfun(@(s) locs_tim(find(locs_tim > s,1)) -1,...
    %         locomotion_idx(1:end-1));
    %     if locomotion_idx(end) == height(times)
    %         loc_end_idx(end + 1,:) = locomotion_idx(end);
    %     else
    %         loc_end_idx(end + 1,:) = locs_tim(find(locs_tim > locomotion_idx(end),1)) -1;
    %     end
    % else
    %     loc_end_idx = locomotion_idx;
    % end

    % locomotion_end_idx = locomotion_idx;
    % for i = 1:length(locomotion_idx)
    %     if locomotion_idx(i) ~= height(times)
    %         if times.seg_category(locomotion_idx(i) + 1) == "Run" |...
    %                 times.seg_category(locomotion_idx(i) + 1) == "Motion"
    %             locomotion_end_idx(i) = locomotion_idx(i) +1;
    %         end
    %     end
    % end

    %
    % cont_loc = times.seg_category(trans_idx + 2) == "Run" |...
    %     times.seg_category(trans_idx + 2) == "Motion";
    % loc_end_idx = locomotion_idx;
    % if any(cont_loc)
    %     loc_end_idx(cont_loc) = locomotion_idx(cont_loc) + 1;
    % end

    %% Transition idxs
    % Still segments idxs
    still_segs = arrayfun(@(s) times.seg_start_f(s):times.seg_end_f(s),...
        still_idx,'UniformOutput',false);
    still_segs_L = cellfun(@length,still_segs);

    % Remove short Still segments (since  2 first and last Still second
    % will be removed, take only still segments that are at least  9 sec
    % long)
    still_segs(still_segs_L < 9*fs ) = [];

    % Remove first and last 2 sec
    still_segs = cellfun(@(s) s(2*fs+1:end - 2 *fs -1),still_segs,...
        'UniformOutput',false);
    still_segs = cellfun(@(s) s(1:length(s) - mod(length(s), 5)),...
        still_segs,'UniformOutput',false);

    % Randomly select 10 or 5 secs from each still segment
    still_segs_L2 = cellfun(@length,still_segs)/fs;
    nsecs = ones(length(still_segs),1) * 5;
    nsecs(still_segs_L2 < 5) = 4; % work around, sometimes it is 4.5 and randperm gives error
    nsecs(still_segs_L2 > 20) = 10;
    mx_slc = floor(still_segs_L2);
    sec_slct = arrayfun(@(s,g)sort(randperm(s,g)),mx_slc,nsecs,...
        'UniformOutput',false);
    still_segs_idx = cellfun(@(g) arrayfun(@(g) g*fs-fs+1:g*fs,g,'UniformOutput',...
        false),sec_slct,'UniformOutput',false);
    still_segs_idx = cellfun(@(s) [s{:}],still_segs_idx,'UniformOutput',false);
    still_idxs = cellfun(@(s,g) s(g),still_segs,still_segs_idx,'UniformOutput',false);

    % Transition segments idxs
    trans_segs_idx = arrayfun(@(s) times.seg_start_f(s):times.seg_end_f(s),...
        trans_idx,'UniformOutput',false);

    % Locomotion segments idxs
    loc_segs_idx = arrayfun(@(s,g) times.seg_start_f(s):times.seg_end_f(g),...
        locomotion_idx,loc_end_idx,'UniformOutput',false);

    % thre are not many locomotion segments less lsting less than 5sec. To
    % simplify the process remove them. however, it coul be interesting to
    % see short lcomotion segments (probably atartle responses)
    lngth_loc_segs = cellfun(@length,loc_segs_idx);
    valid_locs = lngth_loc_segs >= 5*fs;
    loc_segs_idx = loc_segs_idx(valid_locs);

    if ~any(valid_locs)
        nnn = nnn + 1;
        continue
    end

    % also remove the coresponding transition
    trans_segs_idx = trans_segs_idx(valid_locs);

    %% Spike probabilities
    % instead doing this for every roi, do the indexing once, as all
    % belong to the same tsereis and have the same duration.

    spk = ns.trace{1};
    % Spike probability in locomotion by sec
    secs = 1:5;
    loc_by_sec = cell(1,6); % 1:5 sec and the after 5 sec
    for j = 1:length(secs)
        loc_by_sec{j} = cell2mat(cellfun(@(s) s(secs(j)*fs -fs+1:secs(j)*fs),loc_segs_idx,...
            'UniformOutput',false))';
        % Spike probabilty after 5 sec
        if j == 5
            extra = cellfun(@(s) s(secs(j)*fs:end),loc_segs_idx,...
                'UniformOutput',false);
            % durarion in sec of extra seconsd
            dur_extra = cellfun(@(s) length(s)/fs,extra);
            loc_by_sec{j +1} = extra;

            % take only the extra segments (>5sec) that at least have 1
            % sec
            valid_extra = cellfun(@length, extra) > fs;
        end
    end

    % now, take the spike probabilities of all rois
    for i = 1:height(ns)
        % Whole spike trace (each row/segment is a different transition to
        % locomotion. Due to filtering of sgments by duration, segments are
        % It is not pair, meaning not each still segment has a
        % locomotion segment and viceversa
        spk = ns.trace{i};

        trans_spk = cellfun(@(s) spk(s), trans_segs_idx, 'UniformOutput', false);
        trans_spk_mean = cellfun(@(s) mean(s,'omitnan')*fs,trans_spk);

        % all seconds of the spike probabilty trace
        % filter still with still whisking
        still_idxs = 
        rvs_idx = ismember(swhisk_idx,still_idxs{:});
        still_idxs(rvs_idx) = [];
        spk_still = spk([still_idxs{:}]);
        spk_trans = spk([trans_segs_idx{:}]);
        spk_loc = spk([loc_segs_idx{:}]);

        % Spike probability in locomotion by sec
        secs = 1:5;
        spk_sec_trace = cell(length(loc_segs_idx),6);
        loc_spks_sec = zeros(length(loc_segs_idx),5);
        for j = 1:length(secs)
            spk_sec_trace(:,j) = num2cell(spk([loc_by_sec{j}]),1)';

            % Spike probabilty after 5 sec
            if j == 5
                spk_sec_trace(:,j+1) = cellfun(@(s) spk(s),loc_by_sec{j+1},...
                    'UniformOutput',false);
            end
        end

        loc_spks_sec = cellfun(@(s) sum(s,'omitnan'),spk_sec_trace(:,1:5));
        loc_spks_sec(:,end +1) = cellfun(@(s) mean(s,'omitnan')*fs,...
            spk_sec_trace(:,end));

        % remove less than 1 sec extra segs
        loc_spks_sec(~valid_extra,end) = nan;

        % % mean spike probabilty of all transitions
        % trans_mean_loc = mean(loc_spks_sec);

        % % transition with maximum resposiveness (max_idx)
        % [trans_max_loc, max_idx] = max(sum(loc_spks_sec,2));
        % mx_loc = loc_spks_sec(max_idx,:);

        % Spike probability in locomotion by periods (first 2.5 sec  and
        % last 2.5 sec and 5sec, and after 5 sec)
        loc_5 = cell2mat(spk_sec_trace(:,1:5)');
        loc_5_mean = sum(loc_5,"omitnan")/5;
        loc_first = sum(loc_5(1:2.5*fs,:),"omitnan")/2.5;
        loc_last = sum(loc_5(2.5*fs+1:end,:),"omitnan")/2.5;

        % mean_loc_5 = mean(loc_all_mean);
        % mean_loc_first = mean(loc_first);
        % mean_loc_last = mean(loc_last);

        % build table (rois_id,still, rans,1:5,extra,nsec extra,2.5,until5,5,all)
        % still is the same for every transition
        rois_id = repmat(ns.roi_id(i),length(trans_segs_idx),1);
        still_spk = repmat(sum(spk_still,'omitnan')*fs,length(trans_segs_idx),1);
        tab1 = table(rois_id,still_spk,trans_spk_mean);
        tab2 = array2table(loc_spks_sec);
        tab3 = table(dur_extra,loc_first',loc_last',loc_5_mean');
        spk_tab{i} = [tab1,tab2,tab3];
    end
    tab_names = ["Rois id","Still spk","Trans spk","Loc spk 1 sec",...
        "Loc spk 2 sec","Loc spk 3 sec","Loc spk 4 sec","Loc spk 5 sec",...
        "Loc spk after 5 sec", "Duration extra", "Loc First 2.5sec",...
        "Loc last 2.5  sec", "Loc First 5 sec"];
    spk_tabi  = vertcat(spk_tab{:});
    spk_tabi.Properties.VariableNames = tab_names;
    clear spk_tab
end
end