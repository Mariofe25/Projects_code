function trans2stim(tss,runtab,behav,do_replicates,do_boot,do_save)
% Grabs the selected tseries and multitable and plots the means ± std of
% the data during the transition to stimulation. it also counts the rate of
% active rois in baseline vs stimulation (rois w/ at least an event). The
% analysis can be perform in all the data (includes replicates), or
% randomnly selecting one replicate  (aka one recording per fov)
if nargin < 6, do_save = true; end
if nargin < 5, do_boot = false; end
if nargin < 4, do_replicates = false; end
import begonia.data_management.multitable.*
import begonia.logging.*

fs = 30;
ln_trace = unique(cellfun(@length,runtab.trace));

%  virus expression and IVM status (for plot ttiles)
vir_exp = unique(string((tss.load_var('virus'))));
drug = unique(string(tss.load_var('drug')));

% Delta time
dt = unique(runtab.trace_dt);

% If true, randomly select one session per fov (roi)
if do_replicates
    runtab = glyr.random_session(runtab);
end

% rois types
rois_type = unique(runtab.roi_type);
rois_type(ismissing(rois_type)) = [];
rois_type(rois_type == "Gp") = [];
rois_type(rois_type == "ND") = [];

% Speed
speed = runtab(runtab.category == "speed",:);

if behav == "Run"
    % eliminate entities where the mouse is moving backwards
    notrun = cellfun(@(s)  sum(s < 0) > length(s)/2,speed.trace);
    if any(notrun)
        runtab(runtab.entity == speed.entity(notrun),:) = [];
        speed(notrun,:) = [];
    end

    r = 8; % 8 cm
    for i = 1:height(speed)
        sp = speed.trace{i};
        sp = r * 0.017453 * sp;
        sp_base(i) = mode(round(sp(1:2*fs),1));
        sp_trace(:,i) = (sp - abs(sp_base(i)))/abs(sp_base(i));
        sp_stim(i) = (mean(sp(2*fs+1:end),'omitnan') - sp_base(i))/sp_base(i);
    end
else
    sp_trace = zeros(unique(cellfun(@length,speed.trace)),height(speed));
end
% eliminate traces were the baseline is very low, meaning that even it is
% classified as running/motion, there is a long section of the segments that
% is still
if behav == "Run"
    rmv_idx = abs(sp_base) < 5;
    sp_trace(:,rmv_idx) = [];

    % eliminate recordings which lomotion trace have some still segments (in
    % the speed trace)
    rmv_ents = speed.entity(rmv_idx);
    r_ents = arrayfun(@(s) runtab.entity == s,rmv_ents,'UniformOutput',false);
    r_idx = logical(sum(horzcat(r_ents{:}),2));

    runtab(r_idx,:) = [];
    speed = runtab(runtab.category == "speed",:);
end
spp = horzcat(speed.trace{:});
r = 8; % 8 cm
spp = r * 0.017453 * spp;

% Pupil data (relative difference)
pupil = runtab(runtab.category == "pupil_ratio",:);
for i = 1:height(pupil)
    pup = pupil.trace{i};
    pup_base(i) = mean(pup(1:2*fs),'omitnan');
    pup_diam(:,i) = (pup - pup_base(i))/pup_base(i);
    pup_stim(i) = (mean(pup(2*fs+1:end),'omitnan') - pup_base(i))/pup_base(i);
end
pups = horzcat(pupil.trace{:});

% Summary numbers
n_trials = numel(unique(runtab.entity));
n_mouse = numel(unique(runtab.mouse));
n_fovs = numel(unique(runtab.fov));
rois = zeros(length(rois_type),1);
for i = 1:numel(rois_type)
    r = runtab.roi_short_name(runtab.roi_type == rois_type(i));
    rois(i) = numel(unique(r));
end

% Ca2+ traces
for i = 1:numel(rois_type)
    rr = runtab(runtab.roi_type == rois_type(i),:);
    % take the traces
    trace = horzcat(rr.trace{:});
    % smooth roi traces(each individually) and transpose (roi x data_point)
    % for the heatmap
    traces{i} = sgolayfilt(trace,1,21)';
end

%% bootstrap data
tic
disp("Bootstrap of data. Might take some minutes...")
if do_boot
    nruns = 10000;
    for i = 1:numel(rois_type)
        rr = runtab(runtab.roi_type == rois_type(i),:);

        rr.trace = cellfun(@(s) sgolayfilt(s,1,21)', rr.trace ,...
            'UniformOutput', false);

        bootstats_mean = nan(nruns,ln_trace);
        for s = 1:nruns

            % select only one tseries per fov
            un_rr = glyr.random_session(rr);
            %signals = vertcat(un_rr.trace{:});
            %         nrois = height(un_rr);
            %         nrois = ceil(nrois + nrois*0.1);

            [umice,~,nrmice] = unique(un_rr.mouse,'stable');
            nroism = histcounts(nrmice);
            signals = cell(max(nroism),length(umice));
            roiscell = mat2cell(un_rr.trace,nroism)';

            nrois = max(cellfun(@length,roiscell));
            nrois = ceil(nrois + nrois*0.1);

            for k = 1:size(roiscell,2)
                signals(1:length(roiscell{k}),k) = roiscell{:,k};
            end

            signals = signals';

            % level mouse
            num_lev1= numel(umice);
            temp = cell(num_lev1,nrois);
            rand_lev1 = randi(num_lev1,num_lev1,1);
            %rmice(:,s) = rand_lev1;

            % level rois
            for j = 1:length(rand_lev1)
                num_lev2 = find(~cellfun(@isempty,signals(rand_lev1(j),:)),1,'last');
                rand_lev2 = randi(num_lev2,1,nrois);
                temp(j,:) = signals(rand_lev1(j),rand_lev2);
            end
            bootstats_mean(s,:) = mean(vertcat(temp{:}));
        end

        boot_roi{i} = bootstats_mean;
    end
end
toc
%% Plots traces
% heatmap w/ ca2+ traces
f = figure;
for i = 1:length(traces)
    t = traces{i};
    subplot(2,3,i)
    % sort traces by mean ca2+ intensity
    [~,I] = sort(mean(t,2,'omitnan'),'ascend');
    imagesc(t(I,:))
    if i <= 3
        caxis([0 0.5])
    else
        caxis([0 0.25])
    end
    hold on
    xline(2*fs,"r--","LineWidth",2)
    title(rois_type(i))
    ylabel("n RoIs")
end

% Mean traces by roi type
fig = figure("Position",[1000 600 1093 737]);
glyr.plot.roi_type_colors;

% Speed & and pupil size
ax0 = subplot(3,2,1);
yyaxis right
glyr.stdshade(pups',1,0.3,'b',0);
ylabel("Pupil-Eye ratio")
yyaxis left
glyr.stdshade(spp',1,0.3,'k',0);
xline(ax0,2/dt,'LineWidth',2,'LineStyle','--')
ylabel("Speed (cm.s-1)")

title(ax0,"Speed & Pupil baseline vs Stim")
%xlabel(ax0,"Frames")
ax0.YAxis(1).Color = 'k';
ax0.YAxis(2).Color = 'b';
xlim([0,ln_trace])
xticks(0:fs:ln_trace)
xticklabels(xticks/fs)
xlabel("Time (sec)")

%xlim tight
hold off

ax = subplot(3,2,2);
glyr.stdshade(pup_diam',1,0.3,'b',0,0);
hold on
glyr.stdshade(sp_trace',1,0.3,'k',0,0);
title(ax,"Speed & Pupil relative changes baseline vs Stim")
ylabel(ax,"Relavite Baseline/Stim change")
%xlabel(ax,"Frames")
xline(ax,2/dt,'LineWidth',2,'LineStyle','--')
%xlim tight
xlim([0,ln_trace])
xticks(0:fs:ln_trace)
xticklabels(xticks/fs)
xlabel("Time (sec)")
ylim([-0.6 0.4])

hold off

ax1 = subplot(3,2,3);
titl_1 = "Ca2+ Signal during the transition to Stimulation (Run)";
plot_mean_sd(traces,dt,ax1,rois_type,roi_colors,titl_1,0,0)
xlim([0,ln_trace])
xticks(0:fs:ln_trace)
xticklabels(xticks/fs)
xlabel("Time (sec)")
ylim([-0.02 0.15])

% Same plot but with the rois traces rescale
ax2 = subplot(3,2,4);
titl_2 = "Rescale Ca2+ Signal during the transition to Stimulation (Run)";
plot_mean_sd(traces,dt,ax2,rois_type,roi_colors,titl_2,1,0)
xlim([0,ln_trace])
xticks(0:fs:ln_trace)
xticklabels(xticks/fs)
xlabel("Time (sec)")
ylim([-0.02 0.15])

% Summary of number of mice, fovs and entities
ax3 = subplot(3,2,5);
b1 = bar([n_mouse;n_fovs;n_trials]);
b1.FaceColor = "flat";
b1.CData = [0,0,0;0.25,0.25,0.25;0.5,0.5,0.5];
xticklabels(["Mice","FoVs","Trials"])
ylabel(ax3,"n")
title("Analysis data used")

% Summary of number ofuniuqe rois per typeot
ax4 = subplot(3,2,6);
b2 = bar(rois);
b2.FaceColor ="flat";
b2.CData = cell2mat(roi_colors.values');
xticklabels(rois_type)
ylabel(ax4,"n rois")
title(ax4,"Number of rois")

if do_boot
    figb = figure;
    subplot(1,2,1)
    titlb = "Bootstrap Ca2+ Signal during the transition to Stimulation (Run)";
    plot_mean_sd(boot_roi,dt,ax2,rois_type,roi_colors,titlb,0,0)
    ylim([-0.02 0.15])
    xlim([0,ln_trace])
    xticks(0:fs:ln_trace)
    xticklabels(xticks/fs)
    xlabel("Time (sec)")

    subplot(1,2,2)
    prt = 95;
    titlb = "Bootstrap CI "+ prt + " Ca2+ Signal during the transition to Stimulation (Run)";
    plot_mean_sd(boot_roi,dt,ax2,rois_type,roi_colors,titlb,0,1,prt)
    ylim([-0.02 0.15])
    xlim([0,ln_trace])
    xticks(0:fs:ln_trace)
    xticklabels(xticks/fs)
    xlabel("Time (sec)")
end


% save tables and plot
path = "/Volumes/GlyR/GlyR project/Plots/trans_stimulation/" + behav;
if ~ do_replicates
    path = path + "_all";
end
if do_save
    foldername = fullfile(path,vir_exp,drug);

    % heatmap
    heatname = "Heatmap_Ca2+_signals";
    heatpath = fullfile(foldername,heatname);
    begonia.path.make_dirs(heatpath)
    print(f,heatpath,'-r300', '-dpng');
    delete(f)

    if do_boot
        filename = "Bootstrap_Signals_Trans2Stim_" + behav;
        filename = fullfile(foldername,filename);
        begonia.path.make_dirs(filename)
        print(figb,filename,'-r300', '-dpng');
        print(figb,filename,'-r300', '-depsc');
        delete(figb)
    end

    % sumup plots
    filename = "Signals_Trans2Stim_" + behav;
    filename = fullfile(foldername,filename);
    begonia.path.make_dirs(filename)
    print(fig,filename,'-r300', '-dpng');
    print(fig,filename,'-r300', '-depsc');
    delete(fig)

    % tabs
    for i = 1:length(traces)
        t = traces{i}';
        tabname = filename + "_" + rois_type(i) + ".xlsx";
        begonia.path.make_dirs(tabname)
        writematrix(t,tabname)
    end
end

%% Events
% Rois with events before the transition to Stimulation
runtab = in_evs(runtab);

% Events post transition to stimulation
runtab = rmv_evs(runtab);

% cretae traces with event onsets
seg_idx = cellfun(@(s,g) s:g,runtab.seg_start_f,...
    runtab.seg_end_f,'UniformOutput',false);
seg_idx = cellfun(@transpose,seg_idx,'UniformOutput',false);

for i = 1:height(runtab)
    seg = seg_idx{i};
    if isempty(runtab.events{i})
        evs_idx{i,1} = false(length(seg),1);
    else
        evs = [runtab.events{i}.x_start_idx];
        evs_idx{i,1} = ismember(seg,evs);
    end
end
runtab.seg_idx = seg_idx;
runtab.events_traces = evs_idx;

% raster plot events by roi type
for i = 1:length(rois_type)
    rtab = runtab(runtab.roi_type == rois_type(i),:);
    ent = unique(rtab.entity);
    rast = figure;
    for j = 1:length(ent)
        etab = rtab(rtab.entity == ent(j),:);

        lngth = unique(cellfun(@length,etab.events_traces));
        tr_l = 1:lngth;

        for h = 1:height(etab)
            dd = double(etab.events_traces{h});
            if sum(dd) == 0
                continue
            else
                dd(dd == 0) = nan;
                hold on
                scatter(tr_l,dd*j)
            end
            % add rois which event onset is before the start of the
            % trace
            eevs = sum(etab.event_in);
            if eevs > 0
                e_evs = nan(lngth,1);
                e_evs(1:eevs) = 1;
                scatter(tr_l,e_evs * j,'filled')
            end
        end
    end
    xline(60,'k--',"LineWidth",2)
    title(rois_type(i))

    hold off
    if do_save
        foldername = fullfile(path,vir_exp,drug,"Events");
        rastname = rois_type(i);
        rastpath = fullfile(foldername,rastname);
        begonia.path.make_dirs(rastpath)
        print(rast,rastpath,'-r300', '-dpng');
        delete(rast)
    end
end

% Event rate by roi type
entities = unique(runtab.entity);
for i = 1:numel(entities)
    entab = runtab(runtab.entity == entities(i),:);
    [baseline_rate(i,:),stimulation_rate(i,:),fov(i,1)] = summary_events(entab,roi_types);
end

% If non unique fov are present, average event rates from recordings of the
% same fov
un_f = unique(fov);
for f = 1:numel(un_f)
    idx = find(fov == un_f(f));
    if numel(idx) < 2
        bb(f,:) = baseline_rate(idx,:);
        ss(f,:) = stimulation_rate(idx,:);
    else
        bb(f,:) = mean(baseline_rate(idx,:));
        ss(f,:) = mean(stimulation_rate(idx,:));
    end
end

roist = repmat(rois_type',size(baseline_rate,1),1);
roist = roist(:);
b_rr = baseline_rate(:);
s_rr = stimulation_rate(:);
rate = [b_rr;s_rr];

exp_state = sort(repmat(["Baseline";"Stimulation"],size(baseline_rate,1)*...
    numel(rois_type),1));

rate_events = table(rate);
rate_events.exp_state = exp_state;
rate_events.roi_type = [roist;roist];

% plot event rate
fig_r = figure;
boxchart(categorical(rate_events.roi_type),rate_events.rate,...
    'GroupByColor',rate_events.exp_state)
ylabel("Rate")
title("Active RoIs rate Before/After transition to Stimulation")
legend

% event rate correlation plots
bt = array2table(bb,"VariableNames",rois_type);
st = array2table(ss,"VariableNames",rois_type);

if behav == "Run"
    fig_corr = figure;
    subplot(1,2,1)
    corrplot(bt)
    title("Baseline event rate")
    subplot(1,2,2)
    corrplot(st)
    title("Stimulation event rate")
end

% save tables and plot
if do_save
    foldername = fullfile(path,vir_exp,drug,"Events");

    % Rate plot
    rname = "Rate_active_rois";
    rpath = fullfile(foldername,rname);
    begonia.path.make_dirs(rpath)
    print(fig_r,rpath,'-r300', '-dpng');
    delete(fig_r)

    % Correlation plot
    if behav == "Run"
        cname = "Coorrelation";
        cpath= fullfile(foldername,cname);
        begonia.path.make_dirs(cpath)
        print(fig_corr,cpath,'-r300', '-dpng');
        delete(fig_corr)
    end
end
end

function plot_mean_sd(data,dt,ax,rois_type,roi_colors,titl,do_rescale,do_CI,prt)
if nargin < 9, prt = 95; end
if do_CI, alpha = 0.2;else, alpha = 0.3; end
for i = 1:length(data)
    glyr.stdshade(data{i},1,alpha,roi_colors(rois_type(i)),do_rescale,do_CI,prt);
    hold on
end
xlim tight
xline(ax,2/dt,'LineWidth',2,'LineStyle','--')
title(ax,titl)
ylabel(ax,"∆F/F")
hold off
end

function mtab = in_evs(mtab)
% Check for events already present. Which means that the event onset occurs
% before the transition to Stimulation
m = height(mtab);
mtab.event_in = false(height(mtab),1);
for i = 1:m
    events = mtab.events{i};
    if ~isempty(events)
        is_in = [events.x_end_idx] > mtab.seg_start_f{i} & ...
            [events.x_start_idx] < mtab.seg_start_f{i};
        if any(is_in)
            mtab.event_in(i) = true;
        end
    else
        continue
    end
end
end

function mtab = rmv_evs(mtab)
% Check for events that start after the transition
m = height(mtab);
import begonia.logging.*;
for i = 1:m
    backwrite(2,'Filtering segments:%d/%d',i,m)
    events = mtab.events{i};
    if ~isempty(events)
        st =  mtab.seg_start_f{i};
        sp = mtab.seg_end_f{i};

        s = [events.x_start_idx] >= st  & [events.x_start_idx] < sp ;

        % Remove selected events
        events(~s) = [];
        mtab.events{i} = events;

        % If no remaining events in the struct, remove it
        if isempty(events)
            mtab.events{i} = [];
        end
    else
        continue
    end
end
end

function [baseline_rate,stimulation_rate,fov] = summary_events(mtab,roi_types)
% total_rois = glyr.get_nrois(mtab);
fov = unique(mtab.fov);
for i = 1:numel(roi_types)
    rtab = mtab(mtab.roi_type == roi_types(i),:);
    if isempty(rtab)
        baseline_rate(i) = nan;
        stimulation_rate(i) = nan;
    else
        r = unique(rtab.roi_short_name);
        for j = 1:length(r)
            tr = rtab(rtab.roi_short_name == r(j),:);
            if ~isempty(tr.events{:})
                base_rate(j) = any(find(tr.events_traces{:}) < 60);
                stim_rate(j) = any(find(tr.events_traces{:}) >= 60);
            else
                base_rate(j) = 0;
                stim_rate(j) = 0;
            end
        end
        baseline_rate(i) = sum(base_rate)/numel(base_rate);
        stimulation_rate(i) = sum(stim_rate)/numel(stim_rate);
        base_rate = [];
        stim_rate = [];
    end
end
end