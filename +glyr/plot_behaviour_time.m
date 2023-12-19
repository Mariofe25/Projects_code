function plot_behaviour_time(mtab,do_save)
if nargin < 2, do_save = true; end
% Grab the variables needed to later get unique behav. states times
m = mtab(:,[2,5,9,10,12]);
%m(m.exp_state == "Post-Stimulation",:) = [];

% Get uinique behav. state of each fov in ach exp.state
m = unique(m,'stable');

% Rate in each behav state by  fov and exp_state
fovs = unique(m.fov,'stable');
exp = unique(m.exp_state,'stable');
total_state = [];
for i = 1:length(fovs)
    for j = 1:length(exp)
        ss = m.total_sec(m.fov == fovs(i) & m.exp_state == exp(j));
        ss_l = length(ss);
        tot = sum(ss);
        total_state = [total_state;repmat(tot,ss_l,1)];
    end
end

m.total_state = total_state;
m.rate_state = m.total_sec./m.total_state;

mouse = unique(m.mouse);
for i = 1:length(mouse)    
    total_time(i,1) = sum(m.total_sec(m.mouse == mouse(i)));
    run_rate(i,1) = sum(m.total_sec(m.seg_category == "Run" & m.mouse == mouse(i)))/total_time(i,1); 
    still_rate(i,1) = sum(m.total_sec(m.seg_category == "Still" & m.mouse == mouse(i)))/total_time(i,1); 
end

tab_run = table(mouse,total_time,run_rate);
tab_still = table(mouse,total_time,still_rate);

%-------------------------------
%Calculate total time in each fov
for i = 1:length(fovs)
        tb = unique(m.total_state(m.fov == fovs(i) & m.exp_state == "Baseline"));
        ts = unique(m.total_state(m.fov == fovs(i) & m.exp_state == "Stimulation"));
        tp = unique(m.total_state(m.fov == fovs(i) & m.exp_state == "Post-Stimulation"));
        tot = tb + ts + tp;
        m.total_time_fov(m.fov == fovs(i)) = tot;
end
%
 m.rate_fov = m.total_sec./m.total_time_fov;

% make tab with uniuqe mouse & fovs
mm = unique(m(:,{'mouse','fov','total_time_fov'}),'stable');
% make new table with just running
m_run = m(m.seg_category == "Run",:);
f = unique(m_run.fov,'stable');
for i = 1:length(f)
   rate_time(i,1) = sum(m_run.rate_fov(m_run.fov == f(i)));
   mouse(i,1) = unique(m_run.mouse(m_run.fov == f(i)));
end
fov = double(f);
tab_run = table(mouse,rate_time,fov);
tab_run = sortrows(tab_run,'fov');

tab_run = outerjoin(mm,tab_run,'Keys',"fov","RightVariables","rate_time");
tab_run.rate_time(isnan(tab_run.rate_time)) = 0;
tab_run = sortrows(tab_run,'mouse');

mice = unique(tab_run.mouse);
for i = 1:length(mice)
   total_time_mouse(i,1) = sum(tab_run.total_time_fov(tab_run.mouse == mice(i)));
end

mouse_tab = table(mice,total_time_mouse,'VariableNames',{'mouse','total_time'});

tab_run = innerjoin(tab_run,mouse_tab,'Keys',"mouse");
tab_run.weight = tab_run.total_time_fov./tab_run.total_time;


for i = 1:length(mice)
   mo = tab_run(tab_run.mouse == mice(i),:);
   rate_mouse(i,1) = sum(mo.rate_time.*mo.weight)/sum(mo.weight);
end


mouse_tab.run_rate = rate_mouse;


% Boxplots
fig = figure('Position',[1000 271 1428 1066]);
t = tiledlayout(2,1);
title(t,'Time spend in each behaviour state')
nexttile()
boxchart(categorical(m.exp_state),m.rate_state,'GroupByColor',m.seg_category)
ylabel("Rate time")
legend

nexttile()
boxchart(m.seg_category,m.rate_state,'GroupByColor',m.exp_state)
ylabel("Rate time")
legend

% Save it
if do_save
    p = "/Volumes/GlyR/GlyR project/Plots/Behaviour_summary";
    p = sprintf('%s/%s/%s',p,unique(mtab.virus),unique(mtab.exp_category));
end
filename = "Behaviour_state_summary";
filename = fullfile(p,filename);
begonia.path.make_dirs(filename);
print(fig,filename,'-r300', '-dpng');
delete(fig)

run_name = [filename,'_Run_',unique(mtab.virus)];
writetable(tab_run,filename,'FileType','spreadsheet')
end