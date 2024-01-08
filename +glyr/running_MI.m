function [r_MI,CI_rMI,pval,model] = running_MI(mtab,do_by_entity,method,exp_state1,...
    state1,exp_state2,state2,roi_type,do_plots,do_save,...
    still_secs,do_combine,do_fix,loc_secs,loc_selection,do_exclusive, ...
    excl_loc,mmnt)
% Calculate the running modulatory index (MI) of the rois. Find
% the effect of running/locomoiton to roi ∆f/f

% Outputs: r_MI = running modulatory index
%          CI_rMI = 95% medain CI from bootsrp
%
%          model = linear regression model (relation between behaviour state in
%          different experimental states)
if nargin < 19, mmnt = "no_comb"; end % when picking exclusive motion/run segments,
% take only: "all_start" = segments with just the selected locomotion type
% and segmetns which start is the selected loc type (only take that part);
% "start" = in the segments with both motion/run, take only the part that
% goes after the still. "after" = in the segments w/ both loc types, take the
% part that goes imediately after motion/run and is followed by still
if nargin < 17, excl_loc = "Motion"; end % Locomotion type chosen in the combined segments
if nargin < 16, do_exclusive = false; end % If true select pure motion/run right after the still segments
if nargin < 15, loc_selection = "all"; end % seconds selection (1 = 1:30,2 = [31:60]...)
if nargin < 14, loc_secs = 5; end % locomotion segment minimum length
if nargin < 13, do_fix = false; end % fix length of locomotion
if nargin < 12, do_combine = false; end % combine motion and run cats
if nargin < 11, still_secs = 4; end % still segment minimum length
if nargin < 10, do_save = false; end
if nargin < 9, do_plots = true; end
if nargin < 8, roi_type = "NS"; end
if nargin < 7, state2 = "Run"; end
if nargin < 6, exp_state2 = "Stimulation";end
if nargin < 5, state1 = "Run"; end
if nargin < 4, exp_state1 = "Baseline";end
if nargin < 3, method = "entire"; end % entire: whole trace. segs: segments means. subsegs: bootstrap 1s subsegments
if nargin < 2, do_by_entity = false; end % if 'true' pair rois by entity,
% remove the rest
% l = sprintf('Running MI: %s, %s(%s)-%s(%s). Locomotion sec: %s',roi_type,exp_state1,state1,...
%     exp_state2,state2,string(loc_selection));
% begonia.logging.log(1,l)

mtab = mtab(mtab.roi_type == roi_type,:);

% take only traces that are at least 1s long to compute the MI
mtab = mtab(mtab.total_sec > 1,:);

% convert negative values to 0
for i = 1:height(mtab)
    mtab.trace{i}(mtab.trace{i} < 0) = 0;
end

% filter mtab by exp. state & behavior state (combine locomotion: run and
% motion)
if ~do_combine
    tab1 = mtab(mtab.exp_state == exp_state1 & mtab.seg_category == state1,:);
    tab2 = mtab(mtab.exp_state == exp_state2 & mtab.seg_category == state2,:);
    if isempty(tab1) || isempty(tab2)
        return
    end
else
    if state1 == "Run" || state1 == "Motion"
        tab1 = mtab(mtab.exp_state == exp_state1 & (mtab.seg_category == "Motion"...
            | mtab.seg_category == "Run"),:);
        tab1 = combine_locomotion(tab1,do_exclusive,excl_loc,mmnt);
        if do_exclusive
            state1 = mmnt + "-" + excl_loc;

        else
            state1 = "Locomotion";
        end
    else
        tab1 = mtab(mtab.exp_state == exp_state1 & mtab.seg_category == state1,:);
    end
    if state2 == "Run" || state2 == "Motion"
        tab2 = mtab(mtab.exp_state == exp_state2 & (mtab.seg_category == "Motion"...
            | mtab.seg_category == "Run"),:);
        tab2 = combine_locomotion(tab2,do_exclusive,excl_loc,mmnt);
        if do_exclusive
            state2 = mmnt + "-" + excl_loc;

        else
            state2 = "Locomotion";
        end
    else
        tab2 = mtab(mtab.exp_state == exp_state2 & mtab.seg_category == state2,:);
    end
end

l = sprintf('%s MI: %s, %s(%s)-%s(%s). Locomotion sec: %s',state2,roi_type,exp_state1,state1,...
    exp_state2,state2,string(loc_selection));
begonia.logging.log(1,l)

if do_by_entity
    tab1(cellfun(@isempty,tab1.trace),:) = [];
    tab2(cellfun(@isempty,tab2.trace),:) = [];
    % Remove not paired rows (fovs) (needed here to compare tab by row)
    [tab1,tab2] = pair_it(tab1,tab2);

    % Get only traces (rows) with segments from the same entities
    [tab1,tab2] =  pair_by_entity(tab1,tab2);
end

% filter traces segments
if state1 == "Still"
    tab1 = filter_still(tab1,still_secs,method);
    tab1(cellfun(@isempty,tab1.trace),:) = [];
elseif contains(state1,["Run","Motion","Locomotion"])
    tab1 = filter_locomotion(tab1,do_fix,loc_secs,loc_selection,do_exclusive,method);
    tab1(cellfun(@isempty,tab1.trace),:) = [];
end

if state2 == "Still"
    tab2 = filter_still(tab2,still_secs,method);
    tab2(cellfun(@isempty,tab2.trace),:) = [];
elseif contains(state2,["Run","Motion","Locomotion"])
    tab2 = filter_locomotion(tab2,do_fix,loc_secs,loc_selection,do_exclusive,method);
    tab2(cellfun(@isempty,tab2.trace),:) = [];
end

% pair tabs again (if do_by_entity is true, pair tabs again after tab
% filtering, if it is false, this is run for the first time)
[tab1,tab2] = pair_it(tab1,tab2);

% Remove trace indices that fall within the first 5 secs. Reason: ∆F/F is
% unusually high sometimes. (opening of the shutter scares the mice or
% laser/dom  problem
% idxs1 = cellfun(@(s) s > 150,tab1.trace_idxs,'UniformOutput',false);
% idxs2 = cellfun(@(s) s > 150,tab2.trace_idxs,'UniformOutput',false);
%
% traces_1 = tab1.trace;
% traces_2 = tab2.trace;
%
% traces_1 = cellfun(@(s,g) s(g),traces_1,idxs1,'UniformOutput', false);
% traces_2 = cellfun(@(s,g) s(g),traces_2,idxs2,'UniformOutput', false);

% in case all the trace's values fall within the first 5sec, remove it from
% the table, and remove its pair
traces_1 = tab1.trace;
traces_2 = tab2.trace;
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

% Calculate the mean of each trace
switch method
    case "max"
        mean_1 = cellfun(@(s) max(s),traces_1);
        mean_2 = cellfun(@(s) max(s),traces_2);
    case "square"
        mean_1 =  sqrt(cellfun(@(s) mean(s.^2,'omitnan'),traces_1));
        mean_2 =  sqrt(cellfun(@(s) mean(s.^2,'omitnan'),traces_2));
    case "segs"
        tr_means1 = tab1.trace_seg_means;
        tr_means2 = tab2.trace_seg_means;
        mean_1 = cellfun(@(s) mean(round(s,2),'omitnan'),tr_means1);
        mean_2 = cellfun(@(s) mean(round(s,2),'omitnan'),tr_means2);
    case "entire"
        mean_1 = cellfun(@(s) mean(round(s,2),'omitnan'),traces_1);
        mean_2 = cellfun(@(s) mean(round(s,2),'omitnan'),traces_2);
    case "subsegs"
        tr_means1 = tab1.subsegs_boot;
        tr_means2 = tab2.subsegs_boot;
        mean_1 = cellfun(@(s) mean(round(s,2),'omitnan'),tr_means1);
        mean_2 = cellfun(@(s) mean(round(s,2),'omitnan'),tr_means2);
end


% Remove negative means. Give weird results in the MI
ng = mean_1 < 0 | mean_2 < 0;
mean_1(ng) = [];
mean_2(ng) = [];
tab1(ng,:) = [];
tab2(ng,:) = [];
traces_1(ng) = [];
traces_2(ng) = [];

% min_all = min([mean_1;mean_2]);
% mean_1 = mean_1 + abs(min_all);
% mean_2 = mean_2 + abs(min_all);

% Correct for negative values
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

% MI
r_MI = (mean_2 - mean_1)./(mean_2 + mean_1);
r_MI(isnan(r_MI)) = 0;
% r_MI(m12_idx) = 0;

if isempty(r_MI)
    return
end

% need to transform to do the hierarchical bootstrap
[umice,~,nrmice] = unique(tab1.mouse,'stable');
nroism = histcounts(nrmice);
mat = nan(max(nroism),length(umice));
roiscell = mat2cell(r_MI,nroism)';

for k = 1:size(roiscell,2)
    mat(1:length(roiscell{k}),k) = roiscell{:,k};
end

% bootstrap
nruns = 10000;
nrois = max(cellfun(@length,roiscell));
nrois = ceil(nrois + nrois*0.1);

boot_rMI = h_boot(mat,nruns,nrois);
CI_rMI = prctile(boot_rMI, [2.5 97.5]);

% % To account for inter-trial contribution, calculate the bootstrap median CI
% boot_rMI = bootstrp(10000,@median,r_MI);
% CI_rMI = bootci(10000,@mean,r_MI);

% Hypothesis test
pval = 1 - sum(boot_rMI > 0)/length(boot_rMI);
% test = bootstrp(10000,@median,(r_MI- median(r_MI))); % h0 = 0, no difference mean_1 vs mean_2
% pval = mean(test > median(r_MI ));

% Linear regression model
tbl = table(mean_1, mean_2);
if ~isempty(tbl)
    model = fitlm(tbl,'linear');
else
    return
end

if do_plots
    fig = figure('Position',[392 127 1655 1210]);
    layout = tiledlayout(1,3,'TileSpacing','compact');
    SS = [state1,state2];
    titl_st = SS (SS~= "Still");
    if numel(titl_st) > 1, titl_st = titl_st(1); end
    title(layout,l)
    ax1 = nexttile();
    plot(ax1,model);
    axis equal
    t = sprintf('LRM %s, %s(%s)-%s(%s)',roi_type,...
        exp_state1,state1,exp_state2,state2);
    title(t)
    xlabel("Mean ∆F/F " + state1 + " " +  exp_state1)
    ylabel("Mean ∆F/F " + state2 + " " +  exp_state2)
    %     axis([-0.2 1])
    ax2 = nexttile();
    histogram(ax2,r_MI,-1:0.1:1);
    hold on
    xline(median(r_MI),'LineWidth',2);
    tot = length(r_MI);
    tfovs = numel(unique(tab1.fov)); % does not matter which tab (tab1 or tab2)
    tmice = numel(unique(tab1.mouse));
    tt = sprintf('Distribution of %s MI: %s, %s(%s)-%s(%s). Total RoIs: %d.Total FoVs: %d. Total mice: %d',...
        titl_st,roi_type,exp_state1,state1,exp_state2,state2,tot,tfovs,tmice);
    title(tt)
    xlabel(titl_st + " MI")
    ylabel("n " + "rois")

    ax3 = nexttile();
    histogram(boot_rMI)
    hold on
    text(mean(ax3.XLim),ax3.YLim(2)/2,"CI: " + CI_rMI + " pval: " + pval,...
        'FontSize',15)
    title(titl_st + " MI Median Bootsrp 10000 sample distribution")
    ylabel("samples")
end

if do_save
    exp_cat = unique(mtab.exp_category);
    virus = unique(mtab.virus);
    p = "/Volumes/GlyR/GlyR project/Plots/Modulatory_index/Locomotion";
    if do_by_entity
        p = sprintf('%s/%s/%s/%s/%s/%s',p,virus,exp_cat,"tseries_paired",...
            string(loc_selection) + "_sec",roi_type);
    else
        p = sprintf('%s/%s/%s/%s/%s',p,virus,exp_cat,...
            string(loc_selection) + "_sec",roi_type);
    end
    filenam = sprintf('%s(%s)-%s(%s)',exp_state1,state1,...
        exp_state2,state2);
    filename = fullfile(p,filenam);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300', '-dpng');
    delete(fig)

    % tabs
    var_names = {"Mouse","FoV","RoI_id",state1 + "_" +  exp_state1,...
        state2 + "_" +  exp_state2,'MI'};
    var_names = cellfun(@char,var_names,'UniformOutput',false);
    r = table(tab1.mouse,tab1.fov,tab1.roi_short_name,mean_1,mean_2,...
        r_MI,'VariableNames',var_names);
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
    writetable(r,tab_name,'FileType','spreadsheet','Sheet',"MI")

    bo = table(boot_rMI,'VariableNames',"boot_MI");
    writetable(bo,tab_name,'FileType','spreadsheet','Sheet',"boot")

    dur_names = ["n_segs1","mean_dur_seg1","std_dur1","n_segs2",...
        "mean_dur_seg2","std_dur2"];
    dur = table(tab1.n_seg,tab1.mean_seg_dur,tab1.std_seg_dur,...
        tab2.n_seg,tab2.mean_seg_dur,tab2.std_seg_dur,'VariableNames',dur_names);
    writetable(dur,tab_name,'FileType','spreadsheet','Range','J:O')
end
end

function tabr = combine_locomotion(tab,do_exclusive,excl_loc,mmnt)
rois = unique(tab.roi_short_name,'stable');
for r = 1:length(rois)
    roi = tab(tab.roi_short_name == rois(r),:);
    if height(roi) == 1 && ~do_exclusive
        tabr(r,:) = roi;
    elseif height(roi) == 1 && do_exclusive && roi.seg_category == ...
            excl_loc && (mmnt == "nocomb" || mmnt == "no_comb")
        tabr(r,:) = roi;
    elseif height(roi) == 1 && do_exclusive && roi.seg_category ~= ...
            excl_loc
        roi.trace{:} = [];
        tabr(r,:) = roi;
    else
        ents = vertcat(roi.segs_entities{:});
        [~,~,pos] = unique(ents);
        ss = cell(height(roi),1);
        loc_type = cell(height(roi),1);
        traces = cell(height(roi),1);
        for e = 1:height(roi)
            ri = roi.trace_idxs{e};
            rt = roi.trace{e};
            seqlengths = diff([0; find(diff(ri) ~= 1); numel(ri)]);
            segs = mat2cell(ri,seqlengths,1);
            tr =  mat2cell(rt,seqlengths,1);
            ss{e} = segs;
            loc_type{e} = repmat(roi.seg_category(e),length(tr),1);
            traces{e} = tr;
        end

        % find right order of segments
        segments = vertcat(ss{:});
        trace = vertcat(traces{:});
        seg_type = vertcat(loc_type{:});
        f_idx = cellfun(@(s) s(1),segments);

        seg_pos = [pos,f_idx];
        [~,rpos] = unique(seg_pos,'rows');

        segments = segments(rpos);
        trace = trace(rpos);
        seg_type = seg_type(rpos);

        % correct number of segments entity after combining(combination
        % will be done during the locomotion sdegment filtering, but this
        % is needed here just in case the analysis is done pairing the
        % tseries)
        seg_pos = seg_pos(rpos,:);
        endd = cellfun(@(f) f(end),segments);

        % continuity of segments to find the unique entities. After
        % combining, total number of segments will be different, so will be
        % the entities to which they belong
        cont = [0;diff([endd(1:end-1),seg_pos(2:end,2)],[],2)];
        cont(cont~=1) = 0;
        ents_idx = cont ~= 1;
        seg_ents = ents(seg_pos(ents_idx,1));

        % take pure motion/run segments (aka discard any combined segemtent
        % that contains both segment types)
        seg_len = cellfun(@length,segments);
        if do_exclusive
            % convert short end (<= 1-2 sec) of continous segment to
            % previous segment type
            if excl_loc == "Run", extr = 60; else, extr = 30; end
            seg_type(cont == 1 & seg_len <= extr) = seg_type(find(cont == 1 ...
                & seg_len <= extr) -1);

            % short start segments w/ continuation
            shst = find(cont(1:end-1) == 0 & seg_len(1:end-1)<= extr);
            swc = logical(cont(shst + 1));
            segwc = shst(swc);
            seg_type(segwc) = seg_type(segwc + 1);

            if mmnt == "after" || mmnt == "post"
                aft_idx = cont == 1 & seg_type == excl_loc;
                cands = bwconncomp(aft_idx).PixelIdxList;
                vld_aft = seg_type(cellfun(@(s) s(1) -1,cands)) ~= excl_loc;
                % here it could be possible to also take only segments that
                % transition to other state than motion/run
                cands = cands(vld_aft);
                aft = vertcat(cands{:});
                durt = aft;
            else

                % start of the segments motion/run
                st = cont == 0 & seg_type == excl_loc;
                st = find(st);

                % end of segments motion/run
                until = zeros(length(st),1);
                bef = false(length(st),1);
                for i = 1:length(st)

                    % inside segments
                    if i ==length(st)
                        uf = find(cont(1:length(cont) > st(i)) == 0);
                        if isempty(uf)
                            uf = length(cont);
                        else
                            uf = st(i) + uf;
                        end
                        iscont = cont(st(i):uf) == 1;
                        isseg = seg_type(st(i):uf) == excl_loc;
                    else
                        iscont = cont(st(i):st(i+1)) == 1;
                        isseg = seg_type(st(i):st(i+1)) == excl_loc;
                    end
                    next = iscont & isseg;

                    % mark the segments that continue with the other loc type
                    bef(i) = any(iscont & ~isseg);

                    %                 after = find(~(iscont & ~isseg));
                    %                 aft{i} = after(2:end) + st(i) -1;

                    % when to cut the segment
                    if sum(next == 0) > 1
                        unt = find(next(2:end) == 0,1,"first") - 1;
                    else
                        unt = find(next,1,"last") - 1;
                    end
                    if isempty(unt)
                        until(i) = st(i);
                    else
                        until(i)= unt + st(i);
                    end
                end

                dur = num2cell([st,until],2);

                % Take only valid segments (pure motion/run segments)
                % This/These segments will be combined when filtering the
                % locomotion segments. Minimum of 3s segs will also be applied
                % during the locomotion filtering later

                % filter segments by mmnt
                if mmnt == "start" || mmnt == "before"
                    dur(~bef) = [];
                elseif mmnt == "nocomb" || mmnt == "no_comb"
                    dur(bef) = [];
                end
                durt = cellfun(@unique,dur,"UniformOutput",false);
                durt = horzcat(durt{:})';
            end

            if length(unique(durt)) ~= length(durt)
                warning("Something might be wrong with the segment filter.Check!")
            end
            seg_type = seg_type(durt);
            cont = cont(durt);
            seg_pos = seg_pos(durt);
            endd = endd(durt);
            seg_len = seg_len(durt);
            segments = segments(durt);
            trace = trace(durt);

            ents_idx = cont ~= 1;
            if isempty(ents_idx)
                seg_ents = [];
            else
                seg_ents = ents(seg_pos(ents_idx,1));
            end
        end

        % put back in the table
        if do_exclusive
            tabr(r,:) = roi(roi.seg_category == excl_loc,:);
        else
            tabr(r,:) = roi(1,:);
        end
        segments = vertcat(segments{:});
        trace = vertcat(trace{:});
        tabr.segs_entities{r} = seg_ents;
        tabr.trace{r} = trace;
        tabr.trace_idxs{r} = segments;
    end
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
% tab1 = sortrows(tab1,{'fov','roi_short_name'});
% tab2 = sortrows(tab2,{'fov','roi_short_name'});
end

function tab = filter_still(tab,still_secs,method)
% this would not be necessary if the function had multitab_segmented instead of
% merged. But in order to not make a new function,let's separate the
% segments merged and filter them
fs = 30;
trace_boot = zeros(1000,height(tab));
for i = 1:height(tab)

    % take traces idx
    tr_idx = tab.trace_idxs{i};

    % find start idx intra segments
    st = [1;find(diff(tr_idx) ~= 1) + 1];

    % create segments
    segs = cell(1,length(st));
    for j = 1:length(st)
        if j~=length(st)
            segs{j} = tr_idx(st(j)):tr_idx(st(j +  1)-1);
        else
            segs{j} = tr_idx(st(j)):tr_idx(end);
        end
    end

    % filter segments:
    % 1. More than 4 sec (120 frames)
    segs_dlt = cellfun(@length,segs) < still_secs*fs;
    serou = cellfun(@(s) false(1,length(s)),segs(segs_dlt),'UniformOutput',false);
    segs(segs_dlt) = serou;

    % 2. Take after 60 frames (to avoid to some extent taking responses
    % originated in a previous run/motion segment
    for s = 1:length(segs)
        if segs{s}(1) ~= 1 && ~islogical(segs{s})
            segs{s}(1:60) = 0;
        else
            continue
        end
    end

    % remove idx lower that 5s
    for k = 1:length(segs)
        segs{k}(segs{k} < 5*fs) = 0;
    end

    % trace idx
    trace_idx = [segs{:}]';
    valid_idx = trace_idx ~= 0;
    trace_idx(~valid_idx) = [];
    tab.trace_idxs{i} = trace_idx;

    segs(cellfun(@(g) sum(g) == 0,segs)) = [];
    n_segs = sum(cellfun(@any,segs));
    dur_seg = cellfun(@(g) sum(g~=0),segs);
    dur_seg_s = dur_seg/fs;
    mean_seg_dur = mean(dur_seg_s);
    std_seg_dur = std(dur_seg_s);

    % new trace values
    tab.trace{i}(~valid_idx) = [];

    segments = mat2cell( tab.trace{i}, dur_seg);
    seg_means = cellfun(@mean,segments);
    tab.trace_seg_means{i} = seg_means;

    if method == "subsegs"
        if ~isempty(segments)
            trace_boot(:,i) = boot_segs(segments,fs);
        else
            trace_boot(:,i) = 0;
        end
        tab.subsegs_boot{i} = trace_boot(:,i);
    end

    tab.n_seg(i) = n_segs;
    tab.mean_seg_dur(i) = mean_seg_dur;
    tab.std_seg_dur(i) = std_seg_dur;
end
end

function tab = filter_locomotion(tab,do_fix,loc_secs,loc_selection,do_exclusive,method)
fs = 30;
trace_boot = zeros(1000,height(tab));
for i = 1:height(tab)
    if isempty(tab.trace{i}), continue, end
    tr_idx = tab.trace_idxs{i};

    % find start idx intra segments
    seqlengths = diff([0; find(diff(tr_idx) ~= 1); numel(tr_idx)]);
    segs = mat2cell(tr_idx',1,seqlengths);

    %     st = [1;find(diff(tr_idx) ~= 1) + 1];
    %
    %     % create segments
    %     segs = cell(1,length(st));
    %     for j = 1:length(st)
    %         if j~=length(st)
    %             segs{j} = tr_idx(st(j)):tr_idx(st(j + 1)-1);
    %         else
    %             segs{j} = tr_idx(st(j)):tr_idx(end);
    %         end
    %     end

    % 2. Take the x secs (lost selection var)
    if ~isequal(loc_selection,"all")
        if do_fix
            % filter segments:
            segs_dlt = cellfun(@length,segs) < loc_secs*fs;
            serou = cellfun(@(s) false(1,length(s)),segs(segs_dlt),'UniformOutput',false);
            segs(segs_dlt) = serou;

            for s = 1:length(segs)
                if  ~islogical(segs{s})
                    if isequal(loc_selection,1)
                        segs{s}(31:end) = 0;
                    elseif isequal(loc_selection,2)
                        segs{s}([1:30,61:end]) = 0;
                    elseif isequal(loc_selection,3)
                        segs{s}([1:60,91:end]) = 0;
                    elseif isequal(loc_selection,4)
                        segs{s}([1:90,121:end]) = 0;
                    elseif isequal(loc_selection,5)
                        segs{s}([1:120,151:end]) = 0;
                    elseif isequal(loc_selection,"early_w") % first 2.5sec
                        segs{s}(76:end) = 0;
                    elseif isequal(loc_selection,"late_w") % last 2.5 sec (max 5sec segments)
                        segs{s}([1:75,loc_secs*fs+1:end]) = 0;
                    elseif isequal(loc_selection,"post_w")  % after 5 sec
                        segs{s}(1:loc_secs*fs) = 0;
                    end
                else
                    continue
                end
            end
        else
            if any(strcmp(loc_selection,["early_w","late_w","post_w"]))
                % take minimum 3 sec always
                if loc_secs < 3
                    segs_dlt = cellfun(@length,segs) < 3*fs;
                else
                    segs_dlt = cellfun(@length,segs) < loc_secs*fs;
                end
            else
                segs_dlt = cellfun(@length,segs) < loc_selection*fs;
            end
            serou = cellfun(@(s) false(1,length(s)),segs(segs_dlt),'UniformOutput',false);
            segs(segs_dlt) = serou;
            for s = 1:length(segs)
                if  ~islogical(segs{s})
                    if ~isstring(loc_selection) && loc_selection == 1
                        segs{s}(loc_selection*fs + 1:end) = 0;
                    elseif  ~isstring(loc_selection) && loc_selection > 1
                        segs{s}([1:(loc_selection-1)*fs-1,fs*loc_selection + 1:end]) = 0;
                    elseif isequal(loc_selection,"early_w") % first 2.5sec
                        segs{s}(2.5*fs + 1:end) = 0;
                    elseif isequal(loc_selection,"late_w") % last 2.5 sec (max 5sec segments)
                        segs{s}([1:2.5*fs,5*fs+1:end]) = 0;
                    elseif isequal(loc_selection,"post_w")  % after 5 sec
                        segs{s}(1:loc_secs*fs) = 0;
                    else
                        continue
                    end
                end
            end
        end
    else
        % make sure minimum segment length is 3sec
        if do_exclusive
            segs_dlt = cellfun(@length,segs) < 3*fs;
            serou = cellfun(@(s) false(1,length(s)),segs(segs_dlt),'UniformOutput',false);
            segs(segs_dlt) = serou;
        end
    end

    % remove idx lower that 5s
    for k = 1:length(segs)
        segs{k}(segs{k} < 5*fs) = 0;
    end

    % trace idx
    trace_idx = [segs{:}]';
    valid_idx = trace_idx ~= 0;
    trace_idx(~valid_idx) = [];
    tab.trace_idxs{i} = trace_idx;
    tab.trace_idx_selected{i} = valid_idx;

    segs(cellfun(@(g) sum(g) == 0,segs)) = [];
    n_segs = sum(cellfun(@any,segs));
    dur_seg = cellfun(@(g) sum(g~=0),segs);
    dur_seg_s = dur_seg/fs;
    mean_seg_dur = mean(dur_seg_s);
    std_seg_dur = std(dur_seg_s);

    % new trace values
    tab.trace{i}(~valid_idx) = [];

    segments = mat2cell( tab.trace{i}, dur_seg);
    seg_means = cellfun(@mean,segments);
    tab.trace_seg_means{i} = seg_means;

    if method == "subsegs"
        if ~isempty(segments)
            trace_boot(:,i) = boot_segs(segments,fs);
        else
            trace_boot(:,i) = 0;
        end
        tab.subsegs_boot{i} = trace_boot(:,i);
    end

    tab.n_seg(i) = n_segs;
    tab.mean_seg_dur(i) = mean_seg_dur;
    tab.std_seg_dur(i) = std_seg_dur;
end
end

function [tab1,tab2] =  pair_by_entity(tab1,tab2)
% Remove segments that do not share the same entity (in the same fov/session)
tab1 = get_segments(tab1);
tab2 = get_segments(tab2);

for i = 1:height(tab1)
    % common entities
    ents_idx = ismember(tab1.entity{i},tab2.entity{i});
    ents = tab1.entity{i}(ents_idx);
    ents1 = ismember(tab1.segs_entities{i},ents);
    ents2 = ismember(tab2.segs_entities{i},ents);

    % change no match segments values w/ 0 (mark to eliminate)
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

function trace_boot = boot_segs(segments,fs)
% bootstrap the segments of the rois. Split the segments in 1s long
% subsegments and randomly select these one

n = 1000;

for l = 1:length(segments)
    ss = segments{l};

    %  number of sub segments
    num_segments = ceil(length(ss)/fs);

    % split segments  in 1s subsegs
    subsegs = arrayfun(@(d) ss(d:min(d+fs-1,end)),...
        1:fs:length(ss), 'UniformOutput',false);

    % remove subsegments that are less than 0.65*fs
    subsegs(cellfun(@(g) length(g) < 0.65*fs,subsegs)) = [];

    if ~isempty(vertcat(subsegs{:}))
        subsegs_mean{l} = cellfun(@mean,subsegs);
    else
        subsegs_mean{l} = 0;
    end
end

n_segs = length(subsegs_mean);
n_subsegs = cellfun(@length,subsegs_mean);

mat = nan(max(n_subsegs),n_segs);

for k = 1:size(mat,2)
    mat(1:length(subsegs_mean{k}),k) = subsegs_mean{:,k};
end

ns = max(n_subsegs);
ns = ceil(ns + ns*0.1);

trace_boot = h_boot(mat,n,ns);

end


function bootstats_mean =  h_boot(data,nruns,nrois)
% hierarchical bootstrap
d = data';

% n rois from each mouse
% all mouse contribute w/ the same amount of rois. Set a bit higher
% than the max (max = n rois mouse w/ more rois)

bootstats_mean = NaN(nruns,1);
for i =1:nruns

    % level mouse
    num_lev1= size(d,1);
    temp = NaN(num_lev1,nrois);
    rand_lev1 = randi(num_lev1,num_lev1,1);
    rmice(:,i) = rand_lev1;

    % level rois
    for j = 1:length(rand_lev1)
        num_lev2 = find(~isnan(d(rand_lev1(j),:)),1,'last');
        rand_lev2 = randi(num_lev2,1,nrois);
        temp(j,:) = d(rand_lev1(j),rand_lev2);
    end
    bootstats_mean(i) = mean(temp(:));
end
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