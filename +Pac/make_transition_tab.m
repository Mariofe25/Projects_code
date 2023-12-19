function make_transition_tab(tss)
% it takes the indices from the table created with 'align2locon' function
% and makes a table with the roi/speed/pupil traces segmented
import begonia.logging.*
fs = 10;
r = 0;
rr = length(tss);

for ts = tss
    r = r + 1;
    backwrite(1,'Making transition table for tseries: %d/%d',r,rr)
    mtab = ts.load_var('multitab');
    tab_name = "trans_tab";

    if ts.has_var(tab_name)
        tab = ts.load_var(tab_name);
    else
        log(1,ts.name + " does not have " + tab_name + ". Skipping")
        continue
    end

    % remove spike_probability
    mtab(mtab.category == "spikes_prob",:) = [];

    % Selection of transitions with at least 2 secs of pre_transition and 4 secs of
    % post trans
    before_sec = 2; % it is always 2 secs, but it can include nans!
    after_sec = 3; % just in case
    tab(cellfun(@length,tab.after) < fs*after_sec,:) = [];
    tab(cellfun(@length,tab.before) < fs*before_sec,:) = [];
    if isempty(tab), continue; end

    % rois from mtab
    %     mtab = mtab(mtab.categorny == "ca-roi-dff",:);
    mtab(mtab.roi_type == "ND",:) = [];
    mtab(mtab.category == "locomotion",:) = [];

    % transitions ids for the table
    trans_id = arrayfun(@(s) repmat(s,height(mtab),1),tab.ids,'UniformOutput',false);
    trans_id = vertcat(trans_id{:});

    % start
    trs = cellfun(@(s) s(1) + 2*fs,tab.before);
    trans_start = arrayfun(@(s) repmat(s,height(mtab),1),trs,'UniformOutput',false);
    trans_start = vertcat(trans_start{:});

    % rois' traces
    traces = [mtab.trace{:}];

    % trans idx
    trans_idx = arrayfun(@(s) repmat(s,height(mtab),1),tab.trace,'UniformOutput',false);
    trans_idx = vertcat(trans_idx{:});
    trans_start_idx = cellfun(@(s) s(1),trans_idx);
    trans_end_idx = cellfun(@(s) s(end),trans_idx);

    % traces values during transitions
    trans = {};
    for i = 1:height(tab)
        idx = tab.trace{i}';
        idx(isnan(idx)) = [];
        idx_i = ~isnan(tab.trace{i})';
        for t = 1:size(traces,2)
            %handle nans
            tr(:,t) = nan(length(tab.trace{i}'),1);
            tr(idx_i,t) = traces(idx,t);
        end
        trans(:,i) = num2cell(tr,1)';
        tr = []; % clean up
    end
    trans = trans(:);

    % metadata for the table
    seg_category = repmat(mtab.category,height(tab),1);
    roi_id = repmat(mtab.roi_id,height(tab),1);
    mouse = repmat(mtab.mouse,height(tab),1);
    roi_type = repmat(mtab.roi_type,height(tab),1);
    tseries = repmat(mtab.entity,height(tab),1);

    tab_trans = table(mouse,tseries,seg_category,roi_type,roi_id,...
        trans_id,trans,trans_idx,trans_start_idx,trans_end_idx,trans_start);

    % include events of each segment
    tab_trans = select_events(mtab,tab_trans);

    ts.save_var("transtab",tab_trans)
end
end

function tab_trans = select_events(mtab,tab_trans)
% multiple transititions and events
for i = 1:height(tab_trans)
    if ismissing(tab_trans.roi_type(i))
        tab_trans.events{i} = [];
        tab_trans.total_events(i) = 0;
    else
        evs = mtab.events{mtab.roi_id == tab_trans.roi_id(i)};
        % easy way. Some rois will not have event variable empty beacuse they do
        % have events, but these events do not occur in the transition segment
        if ~isempty(evs)
            st = [evs.x_start_idx];
            tab_trans.events{i} = ismember(tab_trans.trans_idx{i},st);
            tab_trans.total_events(i) = sum(tab_trans.events{i});
            if tab_trans.total_events(i) > 0
                valid_evs = ismember(st,tab_trans.trans_idx{i});
                tab_trans.evs{i} = evs(valid_evs);
            else
                tab_trans.evs{i} = [];
            end
        else
            tab_trans.events{i} = [];
            tab_trans.total_events(i) = 0;
            tab_trans.evs{i} = [];
        end
    end
end
end