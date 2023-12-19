function rMI_by_sec(mtab,pair_by_entity,loc_state,do_exclusive,exc_loc)
if nargin < 5, exc_loc = "Motion"; end
if nargin < 4, do_exclusive = false; end
if nargin < 3, loc_state = "Run"; end % Run, Motion or Locomoiton(both combined)
if nargin < 2, pair_by_entity = false; end
exp  = unique(mtab.exp_category);
vir = unique(mtab.virus);

% MI combinations
if loc_state == "Locomotion"
    do_combine = true;
    loc_state = "Run"; % this could be 'Motion', it does not matter
else
    do_combine = false;
end

exp_state_comb = ["Baseline","Baseline";"Stimulation","Stimulation"];
run_comb = ["Still",loc_state;"Still",loc_state];

% Different instances of MI (depends on locomotin secs)
loc_selc = {1,2,3,4,5,6,7,8,9,10,"early_w","late_w","post_w","all"};

% rois types
roi_types = unique(mtab.roi_type);
roi_types(roi_types == "ND") = [];
roi_types(roi_types == "Gp") = [];

% MI
for j = 1:length(roi_types)
    for i = 1:2 % exp state comb
        for k = 1:length(loc_selc)
            [r_MI{j,i,k},CI_rMI{j,i,k},pval{j,i,k}] = glyr.running_MI(mtab,pair_by_entity,...
                "entire",exp_state_comb(i,1),run_comb(i,1),exp_state_comb(i,2),...
                run_comb(i,2),roi_types(j),0,0,4,do_combine,0,5,...
                loc_selc{k},do_exclusive,exc_loc,"no_comb");
        end
    end
end

% Number of rois used to obtain the MI (in the different combinations)
rois_n_base = cellfun(@length,squeeze(r_MI(:,1,:)));
rois_n_stim = cellfun(@length,squeeze(r_MI(:,2,:)));

% median CI
base = squeeze(CI_rMI(:,1,:));
stim = squeeze(CI_rMI(:,2,:));

% pval
base_p = squeeze(pval(:,1,:));
stim_p = squeeze(pval(:,2,:));

% median CI
base_mean = cellfun(@mean,base);
stim_mean = cellfun(@mean,stim);

% ± median CI
base_err = base_mean - cellfun(@(s) s(1),base);
stim_err = stim_mean - cellfun(@(s) s(1),stim);

% Plot CI
path = "/Volumes/GlyR/GlyR project/Plots/Modulatory_index/Locomotion/bysec_comparison";
p = fullfile(path,vir,exp);
if do_combine, loc_state = "Locomotion"; end

for i = 1:length(roi_types)
    fig = figure;
    b = bar([base_mean(i,:);stim_mean(i,:)]');
    hold on

    [ngroups,nbars] = size([base_mean(i,:);stim_mean(i,:)]');
    % Get the x coordinate of the bars
    x = nan(nbars, ngroups);
    for j = 1:nbars
        x(j,:) = b(j).XEndPoints;
    end
    errorbar(x',[base_mean(i,:);stim_mean(i,:)]',[base_err(i,:);stim_err(i,:)]',...
        'LineStyle','none')
    if pair_by_entity
        title(roi_types(i)  + " Running MI by sec" + "_entpaired");
    else
        title(roi_types(i)  + " Running MI by sec")
    end
    ylabel("Median CI running MI")
    labs = [string(loc_selc) + " sec";num2cell(rois_n_base(i,:)); ...
        num2cell(rois_n_stim(i,:))];
    tickLabels = strtrim(sprintf('%s\\newline%s\\newline%s\n', labs{:}));
    ax = gca();
    ax.XTick = 1:length(loc_selc);
    ax.XLim = [0,length(loc_selc)+1];
    ax.XTickLabel = tickLabels;
    legend(["Baseline","Stimulation"])

    % save plot
    fig_name = loc_state + "_MI_bylocsec_" + roi_types(i);
    if do_exclusive
        fig_name = "no_comb-" + exc_loc + "_MI_bylocsec_" + roi_types(i);

    end
    if pair_by_entity
        fig_name = fig_name + "_entpaired";
    end
    fig_path = fullfile(p,fig_name);
    begonia.path.make_dirs(fig_path)
    print(fig,fig_path,'-r300', '-dpng');
    delete(fig)

    %% output table by roi type
    outab = table(horzcat(base(i,:))',base_p(i,:)',horzcat(stim(i,:))',...
        stim_p(i,:)','VariableNames',["Baseline 95% CI", "Base_pval",...
        "Stimulation 95% CI", "Stim_pval"],'RowNames',string(loc_selc));
    if pair_by_entity
        tabname = "/tab/" + roi_types(i) + "_" + loc_state + "_MI_by_sec" + "_entpaired.xlsx";
    elseif do_exclusive && pair_by_entity
        tabname = "/tab/" + roi_types(i) + "_" + "no_comb-" + exc_loc +  "_MI_by_sec" + "_entpaired.xlsx";
    elseif do_exclusive && ~pair_by_entity
        tabname = "/tab/" + roi_types(i) + "_" + "no_comb-" + exc_loc + "_MI_by_sec.xlsx";
    else
        tabname = "/tab/" + roi_types(i) + "_" + loc_state + "_MI_by_sec.xlsx";
    end
    tabpath = fullfile(p,tabname);
    begonia.path.make_dirs(tabpath)
    writetable(outab,tabpath,'WriteRowNames',true)
end
end