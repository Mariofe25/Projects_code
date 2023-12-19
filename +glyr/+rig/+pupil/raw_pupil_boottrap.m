function [pups,btstp,midx,nentities,nmice] = raw_pupil_boottrap(tss,behav,do_figure,do_save_tab,secs,do_weighted,nsamples)
% Take a first look at the mean distribution of the pupil size. This is
% done with the raw data, not the relative size!
if nargin < 7, nsamples = 10000 ;end % times dataset is resampled
if nargin < 6, do_weighted = false; end %occurrence weight in the resampling. 
% the less present a point in the daataset, the more weigth it hasduring th
% resampling
if nargin < 5, secs = 90; end % 3 sec, minimum segment length
if nargin < 4, do_figure = true ;end
if nargin < 3, do_save_tab = false ;end
if nargin < 2, error("Specifiy behavior state: 'Still', 'Run',...");end

mtab = tss.load_var('multitab_segmented');
mtab = vertcat(mtab{:});
tabs = mtab(mtab.category == "pupil_ratio",:);

% Select behavior state (Still,Run,...)
tabs = tabs(tabs.seg_category == behav,:);
tabs(tabs.exp_state == "Post-Stimulation",:) = [];
exp_state = unique(tabs.exp_state);
if do_figure, figure; end

path = "/Volumes/GlyR/GlyR project/Plots/Pupil_size";

for i = 1:numel(exp_state)

    % Select experimental state (Baseline, Stimulation)
    tab = tabs(tabs.exp_state == exp_state(i),:);

    drug = unique(tab.exp_category);

    if isempty(tab), warning("No samples found"), continue; end

    nentities(i) = numel(unique(tab.entity));
    nmice(i) = numel(unique(tab.mouse));

    disp(exp_state(i) + ": Data from " + nentities(i) + " entities and "...
        + nmice(i)  + " nmice")

    % minimum length of segment
    if behav ~= "Transition_still_motion"
        tab(cellfun(@(s) length(s) < secs ,tab.trace),:) = [];
    else
        tab(cellfun(@(s) length(s) ~= 30 ,tab.trace),:) = [];
    end

    % mean segment
    mr = cellfun(@(s) mean(s,'omitnan'),tab.trace);
    mr(isnan(mr)) = [];

    pups = table(tab.mouse,mr,'VariableNames',["Mouse","Mean_Pupil_size"]);
    pups = sortrows(pups,"Mouse");

    if do_save_tab
        name = "Pupil_mean_size_" + exp_state(i) + "_" + behav + "_" +...
            drug + ".xlsx" ;
        filename = fullfile(path,drug,name);
        begonia.path.make_dirs(filename)
        writetable(pups,filename)
    end

    % bootstrapping w/ or w/o weights
    if do_weighted
        tab = boot_weight(tab);
        [mb(:,i),midx{i}] = bootstrp(nsamples,@mean,mr','Weights',tab.weight);
    else
        [mb(:,i),midx{i}] = bootstrp(nsamples,@mean,mr');
    end

    % plot histogram
    hold on
    h = histogram(mb(:,i));
    xlim([0 1])
    xline(mean(mr),'--')
end
btstp = table(mb(:,1),mb(:,2));
btstp.Properties.VariableNames = ["Pup_sz_Baseline","Pup_sz_Stimulation"];

if do_save_tab
    name_bt = "Pup_sz_bootsrp_"  + behav + "_" +...
        drug + ".xlsx" ;
    filename = fullfile(path,drug,name_bt);
    begonia.path.make_dirs(filename)
    writetable(btstp,filename)
end

title("Pupil size mean distribution."  + ...
    " Behavior: " + behav + ". Resampling: " + nsamples)
hold off
end


function tab = boot_weight(tab)
[ents,~,c] = unique(tab.entity,'stable');
C = accumarray(c,1).';
f = 1./C/numel(ents);
for i = 1:numel(ents)
    tab.weight(tab.entity == ents(i)) = f(i);
end
end