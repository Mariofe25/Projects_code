function trans_tab = get_transtab(tss,exp_state)
% Summarized all transitions info in one table (speed, pupil and Ca2+) for
% correlations

%% Get Tabs with transitions
virus = unique(string(tss.load_var('virus')));
drug = string(unique(tss.load_var('drug')));
fs = 30;
n = 0;
tab = cell(1,length(tss));
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
tab.trans_length = tab.trans_length - 3*fs; % 3 --> before(2sec) + trans (1sec)
tab = sortrows(tab,'trans_length');

if ~any(tab.glyr_expression)
    drug  = drug + "_no-glyr";
end


%% Get bahviour tab (tab with the speed and pupil info from each trans)

% Speed (all trans have speed trace)
sp_tab = tab(tab.seg_category == 'speed',:);

trace_start = cellfun(@(s) s(find(~isnan(s),1)),sp_tab.trans_idx,...
    'UniformOutput',false);
trace_start = [trace_start{:}]';

% trans id
trans_id = sp_tab.trans_id;

% Transition speed trace
sp_trace = sp_tab.trans;

% % Speed trace classification. (1 event, multievents and startle)
% for i = 1:length(sp_trace)
%     sp = sp_trace{i}(90:end - fs);
%     dsp = diff(sp);
%     sp_incr = sp > 0;
%     sp_dcr = sp < 0;
% 
%     t_sp_incr = sum(sp_incr);
%     t_sp_dcr = sum(sp_dcr);
%     
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% if t_sp_dcr >= 0.4*length(sp) || 
%     sp_type(i) = "startle";
% elseif 
% 
% else
% 
% end
% end

% Locomotion duration
sp_dur = sp_tab.trans_length/fs; 

% Average speed (las seconf belongs to 'still' period
sp_avg = cellfun(@(d) mean(d(3*fs:end-1*fs),'omitnan'),sp_trace);

% Max speed during transitions (and max location)
[sp_max, mxsp_idx] = cellfun(@(d) max(d(3*fs:end),[],'omitnan'),sp_trace);
sp_max = abs(sp_max);

% Acceleration trace per sec
sp_delta = cellfun(@(d) diff([nan;d])*fs,sp_trace,'UniformOutput',false);

% Average accelration(subtract las second that belongs to 'still' category)
sp_delta_avg = abs(cellfun(@(s) mean(s(3*fs:end-1*fs),'omitnan'),sp_delta));

% Max acceleration
sp_delta_max = cellfun(@max,sp_delta);
sp_delta_max = abs(sp_delta_max);

% Time to max speed from locomotion onset in seconds
time2_sp_max = mxsp_idx/fs;

wheel = table(trans_id,trace_start,sp_trace,sp_delta,sp_dur,sp_avg,...
    sp_max,sp_delta_avg,sp_delta_max,time2_sp_max);

%----------------
% Pupil
pup_tab = tab(tab.seg_category == 'pupil_ratio',:);

% trans id
trans_id = pup_tab.trans_id;

% Transition pupil trace
pup_trace = pup_tab.trans;

% Locomotion duration
% pup_dur = pup_tab.trans_length/fs; 

% Average pupil
pup_avg = cellfun(@(d) mean(d(3*fs:end),'omitnan'),pup_trace);

% Max pupil during transitions (and max location)
[pup_max, mxpup_idx] = cellfun(@(d) max(d(3*fs:end),[],'omitnan'),pup_trace);

% Pupil change trace per sec
pup_delta = cellfun(@(d) diff([nan;d])*fs,pup_trace,'UniformOutput',false);

% Average pupil change
pup_delta_avg = cellfun(@(s) mean(s,'omitnan'),pup_delta);

% Max pupil change
pup_delta_max = cellfun(@(s) max(abs(s)),pup_delta);

% Time to max max pupil from locomotion onset in seconds
time2_pup_max = mxpup_idx/fs;

pupil = table(trans_id,pup_trace,pup_delta,pup_avg,pup_max,pup_delta_avg,...
    pup_delta_max,time2_pup_max);


%% Join speed and pupil tabs
behav_tab = outerjoin(wheel,pupil,"Keys","trans_id","MergeKeys",true);

%% Summarized Ca2+ of each transition (can have different number of transitions)
rois_type = unique(tab.roi_type(~ismissing(tab.roi_type)));
rois_tab = cell(1,length(rois_type));
for r = 1:numel(rois_type)
    
    % select by roi type
    roi_type = rois_type(r);
    tab_r = tab(tab.roi_type == roi_type,:);
    
    % average transitions
    [trans,idx] = unique(tab_r.trans_id,'stable');
    mouse = tab_r.mouse(idx);
    fov = tab_r.fov(idx);
    nrois = nan(length(trans),1);
    active_rois = nan(length(trans),1);
    ratio_arois = nan(length(trans),1);
    ca_traces =  cell(length(trans),1);
    out = nan(length(trans),270);
    for j = 1:length(trans)
        tr = tab_r(tab_r.trans_id == trans(j),:);
        nrois(j) = height(tr);
        active_rois(j) = sum(tr.total_events > 0);
        ratio_arois(j) = active_rois(j)/nrois(j);
        trcs = tr.trans;
        traces = horzcat(trcs{:})';
        ca_traces{j} = traces;
        avg_trace = mean(traces,'omitnan');
        if length(avg_trace) < 270
            out(j,1:length(avg_trace)) = avg_trace;
        else
            out(j,:) = avg_trace(1:270);
        end
    end
    
    rt = repmat(roi_type,length(trans),1);

    ca_avg = num2cell(out,2);

    rois_tab{r} = table(mouse,fov,rt,trans,nrois,active_rois,ratio_arois,ca_traces,ca_avg,...
        'VariableNames',["mouse","fov","roi_type","trans_id", ...
        "total_rois","active_rois","ratio_rois","Ca2+_traces","Ca2+_avg"]);
end

 %% Join behav tab with each roi type.
 rois_tab = vertcat(rois_tab{:});
 trans_tab = outerjoin(behav_tab,rois_tab,"Keys","trans_id","MergeKeys",true);
end
