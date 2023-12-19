function get_behav_rate(tss,do_save)
if nargin < 2, do_save = true; end

mtabs = tss.load_var('multitab');
mtabs = vertcat(mtabs{:});
mtab_loc = mtabs(mtabs.category == "locomotion",:);
mtab_whisking = mtabs(mtabs.category == "whisking",:);
gen = string(unique(mtabs.genotype));

behav = cell(height(mtab_loc),1);
for i = 1:height(mtab_loc)
    loc = mtab_loc.trace{i};
    whisk = mtab_whisking.trace{i};
    loc(loc== "Still" & whisk) = "Still-Whisking";
    behav{i} = loc;
end
mtab_behav = mtab_loc;
mtab_behav.trace = behav;

% All mice
mice = unique(mtab_behav.mouse);
ntss = unique(mtab_behav.entity);
behav_state = vertcat(mtab_behav.trace{:});
nb = histcounts(behav_state);
fig = figure("Position",[100 -507 1909 1024]);
tiledlayout(4,length(mice),'TileSpacing','compact');
nexttile(3,[2 2])
pie(nb)
title(["All " + gen + "mice behav state","Tseries: " + numel(ntss)])
bs = unique(behav_state);
legend(bs,"Position",[0.6599 0.7778 0.1025 0.0759]);

% By mouse
for i = 1:length(mice)
    mouse = mice(i);
    mmtab = mtab_behav(mtab_behav.mouse == mouse,:);
    mntss = unique(mmtab.entity);
    nbm = histcounts(vertcat(mmtab.trace{:}));
    nexttile(2*(length(mice))+i,[2,1])
    pie(nbm)
    title([mouse,"Tseries: " + numel(mntss)])
end

if do_save
    p = "/Volumes/Xiaoyi1/PAC/Analysis/Behaviour_state";
    filename = fullfile(p,"Behaviour_state_" + gen);
    begonia.path.make_dirs(filename);
    print(fig,filename,'-r300','-dpng')
    delete(fig)
end