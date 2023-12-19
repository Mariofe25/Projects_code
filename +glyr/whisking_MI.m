function [w_MI,CI_wMI,m] = whisking_MI(mtab,do_by_entity,do_max,exp_state1,...
    state1,exp_state2,state2,roi_type,do_plots,do_square,do_save,...
    still_secs)
% Calculate the whisking modulatory index (MI) of the rois. That is to find
% the  effect of whisking on the roi ∆f/f

% Outputs: w_MI = whisking modulatory index
%          CI_rMI = 95% medain CI from bootsrp
%          m = linear regression model (relation between behaviour state in
%          different experimental states)


% In the whisking MI the "Still-Whisking" category is not filtered by sec 
% like the "Motion/Run" segments in the running MI because whisking periods
% can have very differnt time duration (from less than a sec to several
% seconds)

if nargin < 12, still_secs = 4; end % still segment minimum length
if nargin < 11, do_save = false; end
if nargin < 10, do_square = false; end
if nargin < 9, do_plots = true; end
if nargin < 8, roi_type = "NS"; end
if nargin < 7, state2 = "Still-Whisking"; end
if nargin < 6, exp_state2 = "Stimulation";end
if nargin < 5, state1 = "Still"; end
if nargin < 4, exp_state1 = "Stimulation";end
if nargin < 3, do_max = false; end
if nargin < 2, do_by_entity = false; end % if 'true' pair rois by entity, 
                                           % remove the rest

l = sprintf('Whisking MI: %s, %s(%s)-%s(%s)',roi_type,exp_state1,state1,...
    exp_state2,state2);
begonia.logging.log(1,l)

mtab = mtab(mtab.roi_type == roi_type,:);

% take only traces that are at least 1s long to compute the MI
mtab = mtab(mtab.total_sec > 1,:);

% filter mtab by exp. state & behavior state
tab1 = mtab(mtab.exp_state == exp_state1 & mtab.seg_category == state1,:);
tab2 = mtab(mtab.exp_state == exp_state2 & mtab.seg_category == state2,:);

if do_by_entity
    % Remove not paired rows (fovs) (needed here to compare tab by row)
    [tab1,tab2] = pair_it(tab1,tab2);
    
    % Get only traces (rows) with segments from the same entities
    [tab1,tab2] =  pair_by_entity(tab1,tab2);
end

% filter traces segments
if state1 == "Still"
    tab1 = filter_still(tab1,still_secs);
    tab1(cellfun(@isempty,tab1.trace),:) = [];
else
    tab1 = filter_whisking(tab1);
    tab1(cellfun(@isempty,tab1.trace),:) = [];
end

if state2 == "Still"
    tab2 = filter_still(tab2,still_secs);
    tab2(cellfun(@isempty,tab2.trace),:) = [];
else
    tab2 = filter_whisking(tab2);
    tab2(cellfun(@isempty,tab2.trace),:) = [];
end

% pair tabs again (if do_by_entity is true, pair tabs again after tab 
% filtering, if it is false, this is run for the first time)
[tab1,tab2] = pair_it(tab1,tab2);

% Remove trace indices that fall within the first 5 secs. Reason: ∆F/F is
% unusually high sometimes. Maybe due to the noise produced by the shutter,eom...
idxs1 = cellfun(@(s) s > 150,tab1.trace_idxs,'UniformOutput',false);
idxs2 = cellfun(@(s) s > 150,tab2.trace_idxs,'UniformOutput',false);

traces_1 = tab1.trace;
traces_2 = tab2.trace;

traces_1 = cellfun(@(s,g) s(g),traces_1,idxs1,'UniformOutput', false);
traces_2 = cellfun(@(s,g) s(g),traces_2,idxs2,'UniformOutput', false);

% in case all the trace's values fall within the first 5sec, remove it from
% the table, and remove its pair 
if any(cellfun(@isempty,[traces_1;traces_2]))    
    tab1.trace = traces_1;
    tab2.trace = traces_2;
    
    ng = cellfun(@isempty,tab1.trace) | cellfun(@isempty,tab2.trace);
    tab1(ng,:) = [];
    tab2(ng,:) = [];
    
    traces_1 = tab1.trace;
    traces_2 = tab2.trace;
end

% if state2 ~= "Transition_still_motion"
%     l_t1 = cellfun(@length,traces_1) < 30;
%     l_t2 = cellfun(@length,traces_2) < 30;
%     to_dlt = (l_t1 + l_t2);
%     to_dlt = to_dlt > 0;
%     traces_1(to_dlt) = [];
%     traces_2(to_dlt) = [];
%     tab1(to_dlt,:) = [];
%     tab2(to_dlt,:) = [];
% end

% transform negative values
% min_both = cellfun(@(s,r) min([s;r]),traces_1,traces_2);
% traces_1 = arrayfun(@(s,d) s{:} + abs(d),traces_1,min_both,'UniformOutput', false);
% traces_2 = arrayfun(@(s,d) s{:} + abs(d),traces_2,min_both,'UniformOutput', false);
% traces_1 = cellfun(@(s,d) s + 0.2,traces_1,'UniformOutput', false);
% traces_2 = cellfun(@(s,d) s + 0.2,traces_2,'UniformOutput', false);

% max_both = cellfun(@(s,r) max([s;r]),traces_1,traces_2);
% % traces_1 = arrayfun(@(s,d) log(s{:} + 1 - d),traces_1,min_both,'UniformOutput', false);
% % traces_2 = arrayfun(@(s,d) log(s{:} + 1 - d),traces_2,min_both,'UniformOutput', false);
% traces_1 = arrayfun(@(s,d,g) (s{:} - d)/(g -d),traces_1,min_both,max_both,'UniformOutput', false);
% traces_2 = arrayfun(@(s,d,g) (s{:} - d)/(g -d),traces_2,min_both,max_both,'UniformOutput', false);
% 
% traces_1 = cellfun(@(s) sgolayfilt(s,1,31),traces_1,'UniformOutput',false);
% traces_2 = cellfun(@(s) sgolayfilt(s,1,31),traces_2,'UniformOutput',false);

% traces_1 = cellfun(@(s) smooth(s),traces_1,'UniformOutput',false);
% traces_2 = cellfun(@(s) smooth(s),traces_2,'UniformOutput',false);
% 

% values bigger than the 20th percentile
% for q = 1:length(traces_1)
%     traces_1{q}(traces_1{q} < prctile(traces_1{q},20)) = [];
%     traces_2{q}(traces_2{q} < prctile(traces_2{q},20)) = [];
% end

% 
% for q = 1:length(traces_1)
%     traces_1{q}(traces_1{q} < 0) = 0;
%     traces_2{q}(traces_2{q} < 0) = 0;
% end

% Remove rois with less than 3 sec of Still-whisking
fs = 30;
if state1 == "Still-Whisking"
    t1_l = cellfun(@length,traces_1) < 3*fs;
else
    t1_l = false(length(traces_1),1);
end
if state2 == "Still-Whisking"
    t2_l = cellfun(@length,traces_2) < 3*fs;
else
    t2_l = false(length(traces_2),1);
end

traces_1(t1_l | t2_l) = [];
tab1(t1_l | t2_l,:) = [];
traces_2(t1_l | t2_l) = [];
tab2(t1_l | t2_l,:) = [];

% Calculate the mean of each trace
if do_max
    mean_1 = cellfun(@(s) max(s),traces_1);
    mean_2 = cellfun(@(s) max(s),traces_2);
else
    if do_square
        mean_1 =  sqrt(cellfun(@(s) mean(s.^2,'omitnan'),traces_1));
        mean_2 =  sqrt(cellfun(@(s) mean(s.^2,'omitnan'),traces_2));
    else
        mean_1 = cellfun(@(s) mean(round(s,2),'omitnan'),traces_1);
        mean_2 = cellfun(@(s) mean(round(s,2),'omitnan'),traces_2);
    end
end

%Remove negative means. Give weird results in the MI 
% ng = mean_1 < 0 | mean_2 < 0;
% mean_1(ng) = [];
% mean_2(ng) = [];

% min_all = min([mean_1;mean_2]);
% mean_1 = mean_1 + abs(min_all);
% mean_2 = mean_2 + abs(min_all);
% %Correct for negative values
% m1_idx = mean_1 < 0 & mean_2 > 0;
% m2_idx = mean_2 < 0 & mean_1 > 0;
% m12_idx = mean_1 < 0 & mean_2 < 0;
% 
% mean_1(m1_idx) = mean_1(m1_idx).^2;
% mean_2(m1_idx) = mean_2(m1_idx) + mean_1(m1_idx);
% 
% mean_2(m2_idx) = mean_2(m2_idx).^2;
% mean_1(m2_idx) = mean_1(m2_idx) + mean_2(m2_idx);
% 
% mean_1(m12_idx) = abs(mean_1(m12_idx));
% mean_2(m12_idx) = abs(mean_2(m12_idx));
% 
% MI
w_MI = (mean_2 - mean_1)./(mean_2 + mean_1);
% w_MI(m12_idx) = 0;

if isempty(w_MI), return, end

% To account for inter trial contribution, calculate the bootstrap median CI
boot_wMI = bootstrp(10000,@median,w_MI);
CI_wMI = bootci(10000,@median,w_MI);

% Hypothesis test
test = bootstrp(10000,@median,(w_MI- median(w_MI))); % h0 = 0, no difference mean_1 vs mean_2
pval = mean(test > median(w_MI));


% Linear regression model
tbl = table(mean_1, mean_2);
if ~isempty(tbl)
    m = fitlm(tbl,'linear');
else
    return
end

if do_plots
    fig = figure('Position',[392 127 1655 1210]);
    layout = tiledlayout(1,3,'TileSpacing','compact');
    title(layout,l)
    ax1 = nexttile();
    plot(ax1,m);
    t = sprintf('LRM %s, %s(%s)-%s(%s)',roi_type,...
        exp_state1,state1,exp_state2,state2);
    title(t)
    xlabel("Mean ∆F/F " + state1 + " " +  exp_state1)
    ylabel("Mean ∆F/F " + state2 + " " +  exp_state2)
    %     axis([-0.2 1])
    ax2 = nexttile();
    histogram(ax2,w_MI,-1:0.1:1);
    hold on
    xline(median(w_MI),'LineWidth',2);
    tot = length(w_MI);
    tt = sprintf('Distribution of whisking MI: %s, %s(%s)-%s(%s). Total RoIs: %d'...
        ,roi_type,exp_state1,state1,exp_state2,state2,tot);
    title(tt)
    xlabel("Whisking MI")
    ylabel("n " + "rois")
    
    ax3 = nexttile();
    histogram(boot_wMI)
    hold on
    text(mean(ax3.XLim),ax3.YLim(2)/2,"CI: " + CI_wMI + " pval: " + pval,...
     'FontSize',15)
    title(" Whisking MI Median Bootsrp 10000 sample distribution")
    ylabel("samples")   
end

if do_save
    exp_cat = unique(mtab.exp_category);
    virus = unique(mtab.virus);
    p = "/Volumes/GlyR/GlyR project/Plots/Modulatory_index/Whisking";
    if do_by_entity
        p = sprintf('%s/%s/%s/%s/%s',p,virus,exp_cat,"tseries_paired",...
            roi_type);
    else
        p = sprintf('%s/%s/%s/%s',p,virus,exp_cat,roi_type);
    end
    filenam = sprintf('%s(%s)-%s(%s)',exp_state1,state1,...
        exp_state2,state2);
    filename = fullfile(p,filenam);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-dpng');
    delete(fig)
    
    % tabs
    var_names = {state1 + "_" +  exp_state1,state2 + "_" +  exp_state2,'MI'};
    var_names = cellfun(@char,var_names,'UniformOutput',false);
    r = table(mean_1,mean_2,w_MI,'VariableNames',var_names);
    tab_name = fullfile(p,'tab',filenam);
    begonia.path.make_dirs(tab_name);
    tab_n1 = state1 + "_" +  exp_state1 + ".xlsx";
    tab_n1 = fullfile(p,'tab',tab_n1);
    begonia.path.make_dirs(tab_n1);
    tab_n2 = state2 + "_" +  exp_state2 + ".xlsx";
    tab_n2 = fullfile(p,'tab',tab_n2);
    begonia.path.make_dirs(tab_n2);
    
    t1 = to_xls(traces_1,tab1);
    t2 = to_xls(traces_2,tab2);
    
    %     write_xls(t1,tab_n1)
    %     write_xls(t2,tab_n2)
    
%     writetable(t1,tab_n1,'FileType','spreadsheet')
%     writetable(t2,tab_n2,'FileType','spreadsheet')
    writetable(r,tab_name,'FileType','spreadsheet')
end
end

function [tab1,tab2] = pair_it(tab1,tab2)
% Remove not paired rows (fovs)
fovs_1 = unique(tab1.fov,'stable');
fovs_2 = unique(tab2.fov,'stable');
fovs_idx = ismember(fovs_1,fovs_2);
fovs_both = fovs_1(fovs_idx);

f1_idx = ismember(tab1.fov,fovs_both);
f2_idx = ismember(tab2.fov,fovs_both);

tab1 = tab1(f1_idx,:);
tab2 = tab2(f2_idx,:);
end

function tab = filter_still(tab,still_secs)
% this would not be necessary if the function had multitab_segmented instead of
% merged. But in order to not make a new function,let's separate the
% segments merged and filter them
fs = 30;
for i = 1:height(tab)
    % take traces idx
    tr_idx = tab.trace_idxs{i};
    
    % find start idx intra segments
    st = [1;find(diff(tr_idx) ~= 1) + 1];
    
    % create segments
    segs = cell(1,length(st));
    for j = 1:length(st)
        if j~=length(st)
            segs{j} = tr_idx(st(j)):tr_idx(st(j + 1)-1);
        else
            segs{j} = tr_idx(st(j)):tr_idx(end);
        end
    end
    
    % filter segments:
    % 1. More than 3 sec (90 frames)
    segs_dlt = cellfun(@length,segs) < still_secs*fs;
    serou = cellfun(@(s) false(1,length(s)),segs(segs_dlt),'UniformOutput',false);
    segs(segs_dlt) = serou;
    
    % 2. Take after 30 frames (to avoid to some extent taking responses
    % originated in a previous run/motion segment
    for s = 1:length(segs)
        if segs{s}(1) ~= 1 && ~islogical(segs{s})
            segs{s}(1:fs*1) = 0;
        else
            continue
        end
    end

    % 3. Remove last 0.5 secs to avoid activity related to whisking to be
    % included in the still segments
    for s = 1:length(segs)
        if segs{s}(1) ~= 1 && ~islogical(segs{s})
            segs{s}(end-(0.5*fs):end) = 0;
        else
            continue
        end
    end

    % trace idx
    trace_idx = [segs{:}]';
    valid_idx = trace_idx ~= 0;
    trace_idx(~valid_idx) = [];
    tab.trace_idxs{i} = trace_idx;
    
    % new trace values
    tab.trace{i}(~valid_idx) = [];
end
end

function tab = filter_whisking(tab)
fs = 30;
for i = 1:height(tab)
    tr_idx = tab.trace_idxs{i};
    seqlengths = diff([0; find(diff(tr_idx) ~= 1); numel(tr_idx)]);
    segs = mat2cell(tr_idx',1,seqlengths);

    segs_dlt = cellfun(@length,segs) < 0.4*fs;
    serou = cellfun(@(s) false(1,length(s)),segs(segs_dlt),'UniformOutput',false);
    segs(segs_dlt) = serou;

    % trace idx
    trace_idx = [segs{:}]';
    valid_idx = trace_idx ~= 0;
    trace_idx(~valid_idx) = [];
    tab.trace_idxs{i} = trace_idx;
    tab.trace_idx_selected{i} = valid_idx;

    % new trace values
    tab.trace{i}(~valid_idx) = [];
end
end

function [tab1,tab2] = pair_by_entity(tab1,tab2)
% Remove segments that do not share the same entity (in the same fov/session)
tab1 = get_segments(tab1);
tab2 = get_segments(tab2);

for i = 1:height(tab1) 
    % common entities
    ents_idx = ismember(tab1.entity{i},tab2.entity{i});
    ents = tab1.entity{i}(ents_idx);
    ents1 = ismember(tab1.segs_entities{i},ents);
    ents2 = ismember(tab2.segs_entities{i},ents);
    
    % change non match segments values w/ 0 (mark to eliminate)
    tab1.segs{i}(~ents1) = cellfun(@(s) s*0, tab1.segs{i}(~ents1), ...
        'UniformOutput', false);
    tab2.segs{i}(~ents2) = cellfun(@(s) s*0, tab2.segs{i}(~ents2), ...
        'UniformOutput', false);
    
    % Modify tab entites variables accordingly
    tab1.segs_entities{i} = tab1.segs_entities{i}(ents1);
    tab2.segs_entities{i} =  tab2.segs_entities{i}(ents2);
    tab1.entity{i} = unique(tab1.segs_entities{i},'stable');
    tab2.entity{i} = unique( tab2.segs_entities{i},'stable');
    
    % Modify trace and trace frames variables removing non match indices
    idx1 = [tab1.segs{i}{:}]' > 0;
    idx2 = [tab2.segs{i}{:}]' > 0;
    tab1.trace_idxs{i} = tab1.trace_idxs{i}(idx1);
    tab1.trace{i} = tab1.trace{i}(idx1);
    tab2.trace_idxs{i} = tab2.trace_idxs{i}(idx2);
    tab2.trace{i} = tab2.trace{i}(idx2);
    
    % clean up segments var
    tab1.segs{i}(~ents1) = [];
    tab2.segs{i}(~ents2) = [];    
end
    
% Remove empty rows(rows that do not have entities in common)
% Since this is pair, is enough to take the row idxs from one tab
dlt = cellfun(@isempty,tab1.trace);
tab1 = tab1(~dlt,:);
tab2 = tab2(~dlt,:);
end

function tab = get_segments(tab)
for i = 1:height(tab)
    tr_idx = tab.trace_idxs{i};
    
    % find start idx intra segments
    st = [1;find(diff(tr_idx) ~= 1) + 1];
    
    % create segments
    segs = cell(1,length(st));
    for j = 1:length(st)
        if j~=length(st)
            segs{j} = tr_idx(st(j)):tr_idx(st(j + 1)-1);
        else
            segs{j} = tr_idx(st(j)):tr_idx(end);
        end
    end
    
    tab.segs{i}= segs';
end
end

function t = to_xls(traces,tab)
mx = max(cellfun(@length,traces));
for i = 1:length(traces)    
    traces{i}(end:mx) = nan;
end

traces = horzcat(traces{:});
names = tab.roi_short_name;
t = array2table(traces,'VariableNames',names);
end

% function write_xls(tab,name)
% % make sure the file does not exist
% if isfile(name + ".xls")
%     delete(name + ".xls")
% end
% if width(tab) > 256
%     warning off
%     k = 1;
%     n = 1 ;
%     l  = width(tab);
%     while  l > 0
%         try
%             t = tab(:,k:k + 256 -1);
%         catch
%             t = tab(:,k:width(tab));
%         end
%         writetable(t,name,'FileType','spreadsheet','Sheet',n)
%         n = n+ 1;
%         k = k + 256;
%         l = l - 256;
%     end
%     warning on
% else
%     writetable(tab,name,'FileType','spreadsheet')
% end
% end