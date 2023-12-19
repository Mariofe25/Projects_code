function make_transition_tab(tss,exp_state)
% it takes the indices from the table created with 'align2locon' function
% and makes a table with the roi traces segmented
if nargin < 2
    error("Defined experimental state: 'Baseline' or 'Stimulation'")
end
import begonia.logging.backwrite
r = 0;
rr = length(tss);
for ts = tss
    r = r + 1;
    backwrite(1,'Making %s transition table: %d/%d',exp_state,r,rr)
    mtab = ts.load_var('multitab');
    tab_name = "trans_tab_" + exp_state;
    if ts.has_var(tab_name)
        tab = ts.load_var(tab_name);
    else
        continue
    end
    
    % rois from mtab
    mtab = mtab(mtab.category == "ca-roi-dff",:);
    mtab(mtab.roi_type == "Gp",:) = [];
    mtab(mtab.roi_type == "ND",:) = [];
    
    % transitions ids for the table
    trans_id = arrayfun(@(s) repmat(s,height(mtab),1),tab.ids,'UniformOutput',false);
    trans_id = vertcat(trans_id{:});
    
    % rois' traces
    traces = [mtab.trace{:}];
    
    % trans idx
    trans_idx = arrayfun(@(s) repmat(s,height(mtab),1),tab.trace,'UniformOutput',false);
    trans_idx = vertcat(trans_idx{:});
    trans_start_idx = cellfun(@(s) s(1),trans_idx);
    trans_end_idx = cellfun(@(s) s(end),trans_idx);
    
    % roi traces values during transitions
    trans = {};
    for i = 1:height(tab)
        idx = tab.trace{i}';
        idx(isnan(idx)) = [];
        idx_i = ~isnan(tab.trace{i});
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
    roi_short_name = repmat(mtab.roi_short_name,height(tab),1);
    fov = repmat(mtab.fov,height(tab),1);
    mouse = repmat(mtab.mouse,height(tab),1);
    roi_type = repmat(mtab.roi_type,height(tab),1);
    tseries = repmat(mtab.entity,height(tab),1);
    
    tab_trans = table(mouse,fov,tseries,roi_type,roi_short_name,...
        trans_id,trans,trans_idx,trans_start_idx,trans_end_idx);
    
    % include events of each segment
    tab_trans = select_events(mtab,tab_trans);
    
    ts.save_var("transtab_" + exp_state,tab_trans)
end
end

function tab_trans = select_events(mtab,tab_trans)
% multiple transititions and events
for i = 1:height(tab_trans)
    evs = mtab.events{mtab.roi_short_name == tab_trans.roi_short_name(i)};
    % easy way. Some rois will not have event variable empty beacuse they do
    % have events, but these events do not occur in the transition segment
    if ~isempty(evs)
        st = [evs.x_start_idx];
        tab_trans.events{i} = ismember(tab_trans.trans_idx{i},st);
        tab_trans.total_events(i) = sum(tab_trans.events{i});
    else
        tab_trans.events{i} = [];
        tab_trans.total_events(i) = 0;
    end
end
end