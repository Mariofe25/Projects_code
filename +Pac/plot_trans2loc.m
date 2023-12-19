function fig = plot_trans2loc(tss,do_active,do_save)
% Plot the speed and pupil size during the transition to locomotion (marked
% by dotted lines). It aslo plots the mean df/f traces ± sem of the the
% different roi types

if nargin < 3, do_save = false; end
if nargin < 2, do_active = false; end

% get transtions tabs
gen = unique(string(tss.load_var('genotype')));
r = 0;
for ts = tss
    r = r +1;
    if ts.has_var("transtab")
        tab{r} = ts.load_var("transtab");
    else
        tab{r} = {};
    end
end
tab(cellfun(@isempty,tab)) = [];
tab = vertcat(tab{:});
tab(tab.roi_type == "NS-dnt",:) = [];
tab(tab.roi_type == "Np",:) = [];

fs = 10;

% Select all or only active rois
if do_active
    tab(tab.seg_category == "ca-roi-dff" & tab.total_events == 0,:) = [];
    aa = "active rois";
else
    aa = "all rois";
end


% total sec: 2sec pretrans + 1sec trans + 6sec locomotion
tab(cellfun(@length,tab.trans) < fs*9,:) = [];

% chop table so that all traces have 2secs + 1secs + 6secs = 90 frames
tab.trans = cellfun(@(s) s(1:9*fs),tab.trans,'UniformOutput',false);

% n recordings and mice
nmice = numel(unique(tab.mouse));
nentities = numel(unique(tab.tseries));

% speed
speed = tab(tab.seg_category == "speed",:);
spp = horzcat(speed.trans{:});

for i = 1:height(speed)
    sp = speed.trans{i};
    sp_base(i) = mode(round(sp(1:fs*1.5),1));
    sp_trace(:,i) = (sp - abs(sp_base(i)))/abs(sp_base(i));
    sp_stim(i) = (mean(sp(fs*2 + 1:end),'omitnan') - sp_base(i))/sp_base(i);
end

% Ca2+ data
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
    traces{i} = trace';
    %traces{i} = sgolayfilt(trace,1,21)';
    r_traces{i} = sgolayfilt(r_ca,1,21)';
end

%% Plot
fig = figure;

% plot spped 
subplot(1,2,1)
glyr.stdshade(spp',1,0.3,'k',0);
xline(2*fs + 1,'LineWidth',2,'LineStyle','--')
xline(3*fs + 1,'r--','LineWidth',2)
ylabel("Speed cm.s-1")
title("Speed Still vs Locomotion")
xlabel("Frames")
ax0 = gca;
ax0.YAxis(1).Color = 'k';
xlim tight

Pac.plot.roi_type_colors;

% Get number of rois by type
ca = tab(tab.seg_category == "ca-roi-dff",:);
total_rois = Pac.get_nrois(ca);
rois = [string(total_rois.keys)',string(total_rois.values')];
rois = join(rois,": ")';

% plot calcium data
subplot(1,2,2)
for i = 1:length(traces)
    glyr.stdshade(traces{i},1,0.3,roi_colors(rois_type(i)),0);
    hold on
end
xlim tight
xline(2*fs + 1,'LineWidth',2,'LineStyle','--')
xline(fs*3 + 1,'r--','LineWidth',2)
xlabel("Frames")
title("Ca2+ data")
annotation('textbox',[.9 .5 .1 .2], ...
    'String',rois,'EdgeColor','none')
ylabel("∆F/F")

sgtitle([gen + " " + aa; "mice: " + nmice + "  entities: " + nentities])
hold off

%% ouput table
outab = get_traces(traces,spp,rois_type);

%% save
if do_save
    path = "/Volumes/Xiaoyi1/PAC/Analysis/Trans2loc";

    folderpath = fullfile(path,gen);
    name = "/plot/Transition_to_locomotion_"+ aa;
    filepath = fullfile(folderpath,name);
    begonia.path.make_dirs(filepath)
    print(fig,filepath,'-r300', '-dpng')
    delete(fig)

    name = "/tab/Transition_to_locomotion_" + aa;
    filepath = fullfile(folderpath,name);
    begonia.path.make_dirs(filepath)
    writetable(outab,filepath,'FileType','spreadsheet')
end
end

function outab = get_traces(traces,spp,rois_type)
for i = 1:length(traces)
    mean_trace(:,i) = mean(traces{i},'omitnan');
    sem_trace(:,i) = std(traces{i},'omitnan')/sqrt(size(traces{i},1));
end
varmean_n = rois_type + "_mean";
varsem_n = rois_type + "_sem";
catab = array2table([mean_trace,sem_trace],'VariableNames',[varmean_n,varsem_n]);
dt = 1/10;
time = [0:dt:9-dt]';
speed_mean = mean(spp','omitnan')';
speed_sem = std(spp','omitnan')'/sqrt(size(spp,2));

outab = [table(time,speed_mean,speed_sem),catab];
end