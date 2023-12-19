function events = pupil_trans2loc(tss,events,rois,exp_state)
% Gets the first pupil onset during the transition to locomotion. 
if nargin < 4, exp_state = "Stimulation"; end
if nargin < 3, rois = "astrocytes"; end

if rois == "astrocytes"
    evs = [events("AE");events("AP");events("AS");];
    rt_idx = startsWith(events.keys,"A");
elseif rois == "neurons"
    evs = [events("NS");events("NS-dnt");events("Np")];
    rt_idx = startsWith(events.keys,"N");
else
   evs = events.values;
   evs = vertcat(evs{:});
   rt_idx = true(1,numel(events.keys));
end

rt = string(events.keys);
rt = rt(rt_idx);

% get transition tabs
fs = 30;
n = 0;
for ts = tss
    n = n +1;
    if ts.has_var("transtab_" + exp_state + "_pup")
        tab{n} = ts.load_var("transtab_" + exp_state + "_pup");
    else
        tab{n} = {};
    end
end
tab(cellfun(@isempty,tab)) = [];
tab = vertcat(tab{:});

% Filter table by length of run/motion part (trans_end - trans_start)
tab.trans_length =  cellfun(@length,tab.trans_idx);
tab.trans_length = tab.trans_length - 3*fs; % before(2sec) + trans (1sec)
tab = sortrows(tab,'trans_length');

%% pupil onset
pupil = tab(tab.seg_category == "pupil_ratio",:);
pupil = pupil(ismember(pupil.trans_id,evs.trans_id),:);

% find changes of at least 4%
[changeIndices,segmentMean3] = cellfun(@(s) ischange(fillmissing(s,'spline'),"Threshold",0.04),...
    pupil.trans,'UniformOutput',false);
ch_idx = cellfun(@find,changeIndices,'UniformOutput',false);

[changeidx,segmentslope] = cellfun(@(s) ischange(fillmissing(s,'spline'),'linear',"Threshold",0.01),...
    pupil.trans,'UniformOutput',false);
ch_idx2 = cellfun(@find,changeidx,'UniformOutput',false);

% Get the first change where the next segment's mean is greater
ch_idx(cellfun(@isempty,ch_idx)) = {nan};

for i = 1:length(ch_idx)
    l = length(ch_idx{i});
    if l > 1
        for j = 1:l
            seg_a = segmentMean3{i}(ch_idx{i}(j)-1);
            seg_b = segmentMean3{i}(ch_idx{i}(j));
            is_incr{i}(j) = seg_b > seg_a;
        end
    elseif l == 1 && ~isnan(ch_idx{i})
        [means,m_idx] = unique(segmentMean3{i},"stable");
        if means(1) < means(2)
            is_incr{i} = 1;
        else
            [mp,mpidx] = max(pupil.trans{i}(m_idx(2):end));
            [md,mdidx] = min(pupil.trans{i}(m_idx(2):mpidx + m_idx(2)));
            mdidx = mdidx + m_idx(2) -1;

            % slope before the min
            slp_n = (md - pupil.trans{i}(m_idx(2)))/(mdidx - m_idx(2));

            if slp_n < 0 && mp-md > 0.05
                ch_idx{i} = mdidx + 1;
            else
                ch_idx{i} = nan;
            end
            is_incr{i} = 1;
        end
    elseif l == 1 && isnan(ch_idx{i})
        ll = length(ch_idx2{i});
        [slv,slpp] = unique(segmentslope{i},'stable');
        p_slp =  find(slv > 0);

        if isempty(p_slp),  is_incr{i} = 1; continue, end

        st_slp = slpp(p_slp);
        sp_slpp = zeros(numel(p_slp),1);
        sp_slpp(1:end-1) = slpp(p_slp(1:end-1) + 1) -1;
        if p_slp(end) == numel(slpp)
            sp_slpp(end) = length(segmentslope{i});
        else
            sp_slpp(end) = slpp(p_slp(end) + 1) -1;
        end

        maxx = arrayfun(@(s,g) max(pupil.trans{i}(s:g)),st_slp,sp_slpp);
        [minn,minndx] = arrayfun(@(s,g) min(pupil.trans{i}(s:g)),st_slp,sp_slpp);

        midx = zeros(1,ll);
        midx(p_slp) = minndx;

        dif_mx_mn = maxx - minn;

        valid = zeros(1,ll);

        valid(p_slp) = dif_mx_mn > 0.05;

        midx(p_slp) = midx(p_slp) + slpp(p_slp)' + 1;

        % remove pupil dilations that start much earlier than the
        % transition (not related)
        if sum(valid) >= 2 && midx(find(valid,1)) < fs
            midx(find(valid,1)) = [];
            valid(find(valid,1)) = [];
        end

        ch_idx{i} = midx';
        is_incr{i} = valid;
    else
        is_incr{i} = 1;
    end
end

select_idx = cellfun(@(s) find(s,1,'first'),is_incr,'UniformOutput',false);
dcr = cellfun(@isempty, select_idx);
ch_idx(dcr) = {nan};
select_idx(dcr) = {1};
% select = [select_idx{:}];
ch_idx = cellfun(@(s,g) s(g),ch_idx,select_idx');

% remove transitions were no change was detected
nope = isnan(ch_idx);
pups = pupil(~nope,:);
ch_idx = ch_idx(~nope);

% Get the segment before the 1st change
mm = ch_idx <= 1.5*fs;
win = repmat(1.5*fs,length(ch_idx),1);
win(mm) = ch_idx(mm) - 1;
bf_seg = cellfun(@(s,g,f) s(g-f:g+10),pups.trans,num2cell(ch_idx),num2cell(win),...
    "UniformOutput",false);

% Simple approach. Take the minimum value to/from the change (1s window)
[~,on_idx] = cellfun(@min,bf_seg);

onset = on_idx + (ch_idx-win) -1;
onset_sec = onset/fs - 3; % -3 seconsd is the time before the locomotion

% Add onsets to table
pups.pupil_onset = onset;
pups.pupil_onset_sec = onset_sec;

% join rois-events_onset tables with pupil onsets table (in each roi type)
for k = 1:numel(rt)
    evs = events(rt(k));
    evs.pupil_onset = nan(height(evs),1);
    [pps,pups_trans] = ismember(pups.trans_id,evs.trans_id);
    pups_trans = nonzeros(pups_trans);
    evs.pupil_onset_f(pups_trans) = pups.pupil_onset(pps);
    evs.pupil_onset(pups_trans) = pups.pupil_onset_sec(pps);
    evs = movevars(evs,'pupil_onset_f', 'After', 'active');
      evs = movevars(evs,'pupil_onset', 'After', 'pupil_onset_f');
    events(rt(k)) = evs;
end

%Check pupil onset
% figure
% for i = 1:height(pups)
%     p = pups.trans{i};
%     on = onset(i);
%     x = 1:length(p);
% 
%     plot(x,p,x(on),p(on),'r*')
%     title(string(i))
%     pause(3)
% end
end