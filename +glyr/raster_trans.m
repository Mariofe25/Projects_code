function raster_trans(tss,loc_t,ivm,do_save)
% Create plots and tabs of the event during transisition to locomotion. #
% different plots. One figure is a raster plot of the events per transition 
% and the event distribution in time (histogram). The other figure includes
% the number of active rois per transisition  and roi type and the response
% reliability

% loc_t: minimum locomotion duration in seconds (part after the transition(

if nargin < 2, loc_t = 0; end
if nargin < 3, ivm = "noIVM"; end
if nargin < 4, do_save = true; end
virus = tss(1).load_var('virus');
baseline = cell(1,length(tss));
stimulation = cell(1,length(tss));
for i = 1:length(tss)
    if tss(i).has_var("transtab_Baseline_pup")
        baseline{i} = tss(i).load_var("transtab_Baseline_pup");
    else
        baseline{i} = {};
    end
    if tss(i).has_var("transtab_Stimulation_pup")
        stimulation{i} = tss(i).load_var("transtab_Stimulation_pup");
    else
        stimulation{i} = {};
    end
end

basetab = vertcat(baseline{:});
basetab(basetab.seg_category ~= "ca-roi-dff",:) = [];
stimtab = vertcat(stimulation{:});
stimtab(stimtab.seg_category ~= "ca-roi-dff",:) = [];

% take only transitions that have at least x sec of locomotion
l_b = cellfun(@length,basetab.trans);
basetab.trans_trace_length = l_b;
l_s = cellfun(@length,stimtab.trans);
stimtab.trans_trace_length = l_s;
if loc_t > 0
    fs = 30;
    % 3 sec of pre-transition (3 * fs)
    lt = 3*fs + fs*loc_t;
    basetab(basetab.trans_trace_length < lt - 30 | ...
        basetab.trans_trace_length  > lt + 1*fs,:) = [];
    stimtab(stimtab.trans_trace_length < lt - 30 |...
        stimtab.trans_trace_length  > lt + 1*fs,:) = [];
end

%% Plot data summarized: % of acticve rois and response reliability
[basetab_summary,basetab_rois,basetab_trans] = sumarize_tab(basetab,"Baseline");
[stimtab_summary,stimtab_rois,stimtab_trans] = sumarize_tab(stimtab,"Stimulation");

roi_types = unique(basetab.roi_type);
active = [basetab_summary.active_rate,stimtab_summary.active_rate];
f = figure;
subplot(3,1,1)
bar(active)
xticklabels(roi_types)
ylabel("Rate activity")
legend(["Baseline","Stimulation"])
title("Rate active RoIs during transition to locomotion")

% join base/stim tabs to create the excel sheet
ntab_summary = [basetab_summary;stimtab_summary];

% Reliability plot. Rois w/ event in multuple transitions (consider only
% the active  rois)
exptab_rois = [basetab_rois;stimtab_rois];
exptab_rois = sortrows(exptab_rois,{'exp_state','roi_type','fov'});
% eliminate rois w/ less than 4 transition
exptab_rois(exptab_rois.n_trans < 4,:) = [];
subplot(3,1,3)
boxchart(categorical(exptab_rois.roi_type),exptab_rois.rate_activity,'GroupByColor',exptab_rois.exp_state)
legend
ylabel("Rate reliability")
title("Response reliability during transition to locomotion")

% boxplot of active rate by roi type
basetrans_rate = take_rate(basetab_trans,roi_types,"Baseline");
stimtrans_rate = take_rate(stimtab_trans,roi_types,"Stimulation");

exp_rate = [basetrans_rate;stimtrans_rate];

subplot(3,1,2)
boxchart(categorical(exp_rate.nam),exp_rate.base_rate,'GroupByColor',exp_rate.exp_state)
legend
ylabel("Rate activity")
title("Activity rate in each roi type")

if do_save
    path = '/Volumes/GlyR/GlyR project/Plots/Events_loctrans';
    filename = "Active_rois-Response reliability_" + ivm;
    filename = fullfile(path,filename);
    begonia.path.make_dirs(filename);
    print(f,filename,'-r300', '-dpng')
    delete(f)
    
    % save tabs
    stabname = "Activity_rate_" + ivm + ".xlsx";
    stabpath = fullfile(path,stabname);
    writetable(ntab_summary,stabpath);
    
    tabname = "Reliability_"+ ivm + ".xlsx";
    tabpath = fullfile(path,tabname);
    writetable(exptab_rois,tabpath);   
    
    expname = "Activity _rate_sd-" + ivm + ".xlsx";
    exppath = fullfile(path,expname);
    writetable(exp_rate, exppath);    
end

%% Plot  active rate and event distribution
% eliminate rois w/o events
basetab(basetab.total_events == 0,:) = [];
stimtab(stimtab.total_events == 0,:) = [];

% make figure w/ rates plot and histogram (event onset time distribution)
raster_histo(basetab,"Baseline",virus,ivm,do_save)
raster_histo(stimtab,"Stimulation",virus,ivm,do_save)
end

function raster_histo(trans_tab,exp_state,virus,ivm,do_save)
trans_align_idx = cellfun(@(s) 1:length(s),trans_tab.trans_idx,'UniformOutput',false);
trans_tab.trans_align_idx = trans_align_idx;
m = max(trans_tab.trans_trace_length);
for i = 1:height(trans_tab)
    trans_tab.trans{i}(end+1:m) = nan;
    trans_tab.events{i}(end+1:m) = 0;
end

trans_tab = sortrows(trans_tab,{'trans_trace_length','roi_type'},'ascend');

% %take only transitions that have at least 5 sec of locomotion
% if loc_t > 0
%     lt = 90 + 30*loc_t;
%     trans_tab(trans_tab.trans_trace_length < lt,:) = [];
% end

% traces = horzcat(trans_tab.trans{:});
types = unique(trans_tab.roi_type);
trans = unique(trans_tab.trans_id,'stable');
for j = 1:numel(types)
    tab = trans_tab(trans_tab.roi_type == types(j),:);
    fig = figure('Position',[1000 673 928 664]);
    subplot(2,1,1)
    for i = 1:numel(trans)
        tr = tab(tab.trans_id == trans(i),:);
        for d = 1:height(tr)
            dd = double(tr.events{d});
            dd(dd == 0) = nan;
            scatter(1:m,i*dd)
            hold on
        end
        
        % draw lines where there is no data
        ll = unique(cellfun(@length,tr.trans_idx));
        line([ll,m],[i i],'LineWidth',1,'Color',[0.8,0.8,0.8])
    end
    
    % add transition lines
    xline(60,'LineWidth',2,'LineStyle','--')
    xline(90,'LineWidth',2,'LineStyle','--','Color','r')
    title("Raster plots Ca2+ events " + types(j) + "_ " + exp_state)
    hold off
    
    %% Plot the histogram showing event occurrence relative to locomotion transition
    % get events from tab
    evnts = vertcat(tab.events{:})';
    
    % create a vector from 0 to the (max) length of the transition(s)
    tr_l = 0:1/30:m/30 - 1/30;
    
    % subtract pre-locomotion trace seconds (3)
    tr_l = tr_l - 90*1/30;
    %     evs = evnts;
    % event onset
    for e = 1:size(evnts,2)
        evs(:,e) = evnts(:,e).*tr_l';
    end
    
    % convert event to a vector and remove sec w/o events
    evs = vertcat(evs);
    evs(evs == 0) = [];
    
    % histogram
    subplot(2,1,2)
    histogram(evs,-3:10)
    title("Distribution Ca2+ evetns onset w/ respect to locomtion trasition")
    ylabel("n events")
    xlabel("Time (secs)")
    evs = []; % clean up
    
    % save it
    if do_save
        path = '/Volumes/GlyR/GlyR project/Plots/Events_loctrans';
        path = fullfile(path,virus,ivm);
        filename = "Ca2+ events_transloc_" + exp_state + "_" + types(j);
        filename = fullfile(path,filename);
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng')
        delete(fig)
    end
end
end

function [summ_tab,rois_tab,evt_tab] =  sumarize_tab(ntab,exp_st)

% summarized table with total number of rois and active rois
roi_types = unique(ntab.roi_type);
for i = 1:numel(roi_types)
    t_rois = unique(ntab.roi_short_name(ntab.roi_type == roi_types(i)),'stable');
    rois_total(i,1) = numel(t_rois);
    a_rois = unique(ntab.roi_short_name(ntab.total_events > 0  & ntab.roi_type == roi_types(i)),'stable');
    rois_active(i,1) = numel(a_rois);
end

summ_tab = table(roi_types,rois_total,rois_active);
summ_tab.active_rate = summ_tab.rois_active./summ_tab.rois_total;
summ_tab.exp_state = repmat(exp_st,length(roi_types),1);

% table showing activity rate of each roi
rois = unique(ntab.roi_short_name,'stable');
for j = 1:length(rois)
    roi = ntab(ntab.roi_short_name == rois(j),:);
    n_trans(j,1) = height(roi);
    active_trans(j,1) = sum(roi.total_events > 0);
    rate_activity(j,1) = active_trans(j)/n_trans(j);
    fov(j,1) = unique(roi.fov);
    roi_type(j,1) = unique(roi.roi_type);
end
exp_state = repmat(exp_st,length(rois),1);
rois_tab = table(exp_state,rois,roi_type,fov,n_trans,active_trans,rate_activity);
rois_tab(rois_tab.rate_activity == 0,:) = [];

% table showing the activity rate per transition (and roi type)
trans = unique(ntab.trans_id);
for t = 1:length(roi_types)
    rtab = ntab(ntab.roi_type == roi_types(t),:);
    for r = 1:length(trans)
        ttab = rtab(rtab.trans_id == trans(r),:);
        total(r,t) = height(ttab);
        active(r,t) = sum(ttab.total_events > 0);
        rate(r,t) = active(r,t)/total(r,t);
    end
end
tname = roi_types + "_total";
aname = roi_types + "_active";
rname = roi_types + "_rate";

varnames = [tname',aname',rname'];
mat = [total,active,rate];

evt_tab = array2table(mat,'VariableNames',varnames,'RowNames',trans);
end

function rate_tab = take_rate(ntab_trans,roi_types,exp_state)
nam = sort(repmat(roi_types,height(ntab_trans),1));
% rate table variables
base_rate = ntab_trans{:,13:18};
% put in vector form
base_rate = base_rate(:);
% make table
rate_tab = table(nam,base_rate);
rate_tab.exp_state = repmat(exp_state,height(rate_tab),1);
end