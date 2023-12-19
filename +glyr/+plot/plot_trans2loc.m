function fig = plot_trans2loc(tss,exp_state,do_active,do_save)
% Plot the speed and pupil size during the transition to locomotion (marked
% by dotted lines). It aslo plots the mean df/f traces ± sem of the the
% different roi types

if nargin < 4, do_save = false; end
if nargin < 3, do_active = false; end
if nargin < 2, exp_state = "Stimulation"; end

% get transtions tabs
virus = unique(string(tss.load_var('virus')));
drug = string(unique(tss.load_var('drug')));
r = 0;
for ts = tss
    r = r +1;
    if ts.has_var("transtab_" + exp_state + "_pup")
        tab{r} = ts.load_var("transtab_" + exp_state + "_pup");
    else
        tab{r} = {};
    end
end
tab(cellfun(@isempty,tab)) = [];
tab = vertcat(tab{:});

fs = 30;

% Select all or only active rois
if do_active
    tab(tab.seg_category == "ca-roi-dff" & tab.total_events == 0,:) = [];
    aa = "active rois";
else
    aa = "all rois";
end

% % before transition segment of 1 sec
% for i = 1:height(tab)
%     idx = tab.trans_idx{i} == tab.trans_start(i));
%     tab.trans{i} = tab.trans{i}(idx - 1*fs:end);
% end


% for i = 1:height(tab)
% %     idx = find(tab.trans_idx{i} == tab.trans_start(i));
% %     tab.trans{i} = tab.trans{i}(idx - 1*fs:end);
%    tab.trans{i} = tab.trans{i}(fs+1:end);
% end

% Remove transitions that occurs in the first 5 sec of the recording. Very
% often the ∆F/F signal is unusually high. Only afects 'Baseline'.
tab(tab.trans_start_idx < 150,:) = [];

% total sec: 2sec pretrans + 1sec trans + 5 sec locomotion
tab(cellfun(@length,tab.trans) < fs*8,:) = [];

% chop table so that all traces have 2secs + 1secs + 5secs = 240 frames
tab.trans = cellfun(@(s) s(1:240),tab.trans,'UniformOutput',false);

% n recordings, mice, fovs
nmice = numel(unique(tab.mouse));
nentities = numel(unique(tab.tseries));
nfovs = numel(unique(tab.fov));

% pupil data
pupil = tab(tab.seg_category == "pupil_ratio",:);
pups = horzcat(pupil.trans{:});
ents_pup = pupil.tseries;
for i = 1:height(pupil)
    pup = pupil.trans{i};
    pup_base(i) = mode(round(pup(1:fs*2),2));
    pup_diam(:,i) = (pup - pup_base(i))/pup_base(i);
    pup_stim(i) = (mean(pup(fs*2 + 1:end),'omitnan') - pup_base(i))/pup_base(i);
end

% speed
speed = tab(tab.seg_category == "speed",:);
% speed = speed(ismember(speed.tseries,ents_pup),:);
spp = horzcat(speed.trans{:});
% Convert speed trace to cm/s (v = r*w)(w in rad/s)
r = 0.08; % 8 cm (in m)
spp = r * 0.017453 * spp * 100; %cm/s

for i = 1:height(speed)
    sp = speed.trans{i};
    sp_base(i) = mode(round(sp(1:fs*1.5),1));
    sp_trace(:,i) = (sp - abs(sp_base(i)))/abs(sp_base(i));
    sp_stim(i) = (mean(sp(fs*2 + 1:end),'omitnan') - sp_base(i))/sp_base(i);
end

% ca2+ data
rois_type = unique(tab.roi_type);
rois_type(ismissing(rois_type)) = [];
for i = 1:numel(rois_type)
    rr = tab(tab.roi_type == rois_type(i),:);
    % take the traces
    trace = horzcat(rr.trans{:});
    ca_base = mode(round(trace(1:fs*1.5,:) + 1000,2));
    r_ca = (1000 + trace - ca_base)./ca_base;
    % smooth roi traces(each individually) and transpose (roi x data_point)
    % for the heatmap
    traces{i} = sgolayfilt(trace,1,21)';
    r_traces{i} = sgolayfilt(r_ca,1,21)';
end

%% Plot
fig = figure;

% plot spped + pupil data
subplot(1,2,1)
yyaxis right
glyr.stdshade(pup_diam',1,0.3,'b',0);
ylabel("Relative Pupil-Eye ratio")
yyaxis left
glyr.stdshade(spp',1,0.3,'k',0);
xline(2*fs + 1,'LineWidth',2,'LineStyle','--')
xline(fs*3 + 1,'r--','LineWidth',2)
ylabel("Speed cm.s-1")
title("Speed & Pupil Still vs Locomotion")
xlabel("Time (sec)")
ax0 = gca;
ax0.YAxis(1).Color = 'k';
ax0.YAxis(1).Limits = [0,10];
ax0.YAxis(2).Color = 'b';
ax0.YAxis(2).Limits = [-0.05,0.3];
%xlim tight
xlim([0,240])
xticks(0:30:240)
xticklabels(xticks/fs)

glyr.plot.roi_type_colors;

% Get number of rois by type
ca = tab(tab.seg_category == "ca-roi-dff",:);
total_rois = glyr.get_nrois(ca);
rois = [string(total_rois.keys)',string(total_rois.values')];
rois = join(rois,": ")';

% plot calcium data
subplot(1,2,2)
for i = 1:length(traces)
    glyr.stdshade(traces{i},1,0.3,roi_colors(rois_type(i)),0);
    hold on
end
%xlim tight
xline(2*fs + 1,'LineWidth',2,'LineStyle','--')
xline(fs*3 + 1,'r--','LineWidth',2)
xlabel("Time (sec)")
title("Ca2+ data")
annotation('textbox',[.9 .5 .1 .2], ...
    'String',rois,'EdgeColor','none')
ylabel("∆F/F")
ylim([-0.05,0.3])
xlim([0,240])
xticks(0:30:240)
xticklabels(xticks/fs)


sgtitle([virus + " " + drug + " " + exp_state + " " + aa;...
    "mice: " + nmice + "  fovs: " + nfovs + "  trials: " + nentities])
hold off

%% ouput table
outab = get_traces(traces,pup_diam,spp,rois_type);

%% save
if do_save
    path = "/Volumes/GlyR/GlyR project/Plots/Trans2loc";

    if ~any(tab.glyr_expression)
        drug  = drug + "_no-glyr";
    end
    
    folderpath = fullfile(path,virus,drug);
    name = "/plot/Transition_to_locomotion_" + exp_state + "_" + aa;
    filepath = fullfile(folderpath,name);
    begonia.path.make_dirs(filepath)
    print(fig,filepath,'-r300', '-depsc')
    delete(fig)

    name = "/tab/Transition_to_locomotion_" + exp_state + "_" + aa;
    filepath = fullfile(folderpath,name);
    begonia.path.make_dirs(filepath)
    writetable(outab,filepath,'FileType','spreadsheet')
end
end

function outab = get_traces(traces,pup_diam,spp,rois_type)
for i = 1:length(traces)
    mean_trace(:,i) = mean(traces{i},'omitnan');
    sem_trace(:,i) = std(traces{i},'omitnan')/sqrt(size(traces{i},1));
end
varmean_n = rois_type + "_mean";
varsem_n = rois_type + "_sem";
catab = array2table([mean_trace,sem_trace],'VariableNames',[varmean_n,varsem_n]);
dt = 1/30;
time = [0:dt:8-dt]';
pup_mean = mean(pup_diam','omitnan')';
pup_sem = std(pup_diam','omitnan')'/sqrt(size(pup_diam,2));
speed_mean = mean(spp','omitnan')';
speed_sem = std(spp','omitnan')'/sqrt(size(spp,2));

outab = [table(time,pup_mean,pup_sem,speed_mean,speed_sem),catab];
end