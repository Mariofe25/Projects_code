function [tab,tab_fovs,tab_mouse]= get_locomotion_rate(tss, do_save)
if nargin < 2, do_save = true; end
% all these could be done much easier but the code was reuse
s =  strings(length(tss),1);
ss = zeros(length(tss),1);
mouse = s;
fov = s;
recording_time = ss;
run_rate = ss;
still_rate = ss;
% 
i = 1;
for ts = tss   
    mtab = ts.load_var('multitab');    
    mouse(i) = unique(mtab.mouse);
    fov(i) = unique(mtab.fov);
    l = unique(cellfun(@length,mtab.trace));
    recording_time(i) = l * unique(mtab.trace_dt);
    loc = mtab.trace{mtab.category == "locomotion"};
    run_rate(i) = sum(loc == "Run")/l;
    still_rate(i) = sum(loc == "Still")/l;
   
i = i+1;    
end


% table with run/still rates per tseries
tab = table(mouse,fov,recording_time,run_rate,still_rate);

%clean up
run_rate = [];
still_rate = [];

%% table with run/still per mouse
mtab = glyr.mtab_merge_states(tss);
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

tab_mouse = table(mouse,total_time,run_rate,still_rate);

%tab_still = table(mouse,total_time,still_rate);
%%  table with run/still per fov
run_rate = [];
still_rate = [];
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
m_still = m(m.seg_category == "Still",:);
f = unique(m_run.fov,'stable');
for i = 1:length(f)
   run_rate(i,1) = sum(m_run.rate_fov(m_run.fov == f(i)));
   mouse_run(i,1) = unique(m_run.mouse(m_run.fov == f(i)));
end
fov = double(f);

tab_run = table(mouse_run,run_rate,fov,'VariableNames',{'mouse','run_rate','fov'});
tab_run = sortrows(tab_run,'fov');
tab_run = outerjoin(mm,tab_run,'Keys',"fov","RightVariables","run_rate");
tab_run.run_rate(isnan(tab_run.run_rate)) = 0;
tab_run = sortrows(tab_run,'mouse');

f = unique(m_still.fov,'stable');
for i = 1:length(f)
   still_rate(i,1) = sum(m_still.rate_fov(m_still.fov == f(i)));
   mouse_still(i,1) = unique(m_still.mouse(m_still.fov == f(i)));
end

fov = double(f);
tab_still = table(mouse_still,still_rate,fov,'VariableNames',{'mouse','still_rate','fov'});
tab_still = sortrows(tab_still,'fov');
tab_still = outerjoin(mm,tab_still,'Keys',"fov","RightVariables","still_rate");
tab_still.still_rate(isnan(tab_still.still_rate)) = 0;
tab_still = sortrows(tab_still,'mouse');



tab_fovs = join(tab_run,tab_still);


%% Save_tabs

if do_save
%     p = '/Users/Mario/Documents/test';
    p = "/Volumes/GlyR/GlyR project/Plots/Behaviour_summary";
    p = sprintf('%s/%s/%s',p,unique(mtab.virus),unique(mtab.exp_category));
end
filename_ts = fullfile(p,"_by_tseries_" + unique(mtab.exp_category));
filename_fovs = fullfile(p,"_by_fov_" + unique(mtab.exp_category));
filename_mouse = fullfile(p,"_by_mouse_" + unique(mtab.exp_category));
begonia.path.make_dirs(filename_ts);
begonia.path.make_dirs(filename_fovs);
begonia.path.make_dirs(filename_mouse);

writetable(tab,filename_ts,'FileType','spreadsheet')
writetable(tab_fovs,filename_fovs,'FileType','spreadsheet')
writetable(tab_mouse,filename_mouse,'FileType','spreadsheet')


