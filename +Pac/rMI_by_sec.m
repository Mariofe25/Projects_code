function rMI_by_sec(mtab,method,loc_state,do_exclusive,exc_loc)
if nargin < 5, exc_loc = "Motion"; end
if nargin < 4, do_exclusive = false; end
if nargin < 3, loc_state = "Run"; end % Run, Motion or Locomoiton(both combined)
if nargin < 2, method = "seg"; end

gen = string(unique(mtab.genotype));

% MI combinations
if loc_state == "Locomotion"
    do_combine = true;
    loc_state = "Run"; % this could be 'Motion', it does not matter
else
    do_combine = false;
end

run_comb = ["Still",loc_state];

% Different instances of MI (depends on locomotin secs)
loc_selc = {1,2,3,4,5,6,7,8,9,10,"early_w","late_w","post_w","all"};

% rois types
roi_types = unique(mtab.roi_type);
roi_types(roi_types == "ND") = [];

% MI
for j = 1:length(roi_types)
        for k = 1:length(loc_selc)
            [r_MI{j,k},CI_rMI{j,k},pval{j,k}] = Pac.running_MI(mtab,method,...
                run_comb(1),run_comb(2),roi_types(j),0,0,4,do_combine,0,5,...
                loc_selc{k},do_exclusive,exc_loc,"no_comb");
        end
end

% % Number of rois used to obtain the MI (in the different combinations)
roisn = cellfun(@length,r_MI);
% rois_n_stim = cellfun(@length,squeeze(r_MI(:,2,:)));
% 
% % median CI
% base = squeeze(CI_rMI(:,1,:));
% stim = squeeze(CI_rMI(:,2,:));
% 
% % pval
% base_p = squeeze(pval(:,1,:));
% stim_p = squeeze(pval(:,2,:));

% median CI
CI_mean = cellfun(@mean,CI_rMI);
% stim_mean = cellfun(@mean,stim);

% ± median CI
CI_err = CI_mean - cellfun(@(s) s(1),CI_rMI);
% stim_err = stim_mean - cellfun(@(s) s(1),stim);

% Plot CI
path = "/Volumes/Xiaoyi1/PAC/Analysis/Modulatory_index/Locomotion/bysec_comparison";
p = fullfile(path,gen);
if do_combine, loc_state = "Locomotion"; end

for i = 1:length(roi_types)
    fig = figure;
    b = bar(CI_mean(i,:)');
    hold on
    [ngroups,nbars] = size(CI_mean(i,:)');
    % Get the x coordinate of the bars
    x = nan(nbars, ngroups);
    for j = 1:nbars
        x(j,:) = b(j).XEndPoints;
    end
    errorbar(x',CI_mean(i,:)',CI_err(i,:)','LineStyle','none')

    title(roi_types(i)  + " Running MI by sec")

    ylabel("Median CI running MI")
    labs = [string(loc_selc) + " sec";num2cell(roisn(i,:))];
    tickLabels = strtrim(sprintf('%s\\newline%s\n', labs));
    ax = gca();
    ax.XTick = 1:length(loc_selc);
    ax.XLim = [0,length(loc_selc)+1];
    ax.XTickLabel = tickLabels;

    % save plot
    fig_name = loc_state + "_MI_bylocsec_" + roi_types(i);
    if do_exclusive
        fig_name = "no_comb-" + exc_loc + "_MI_bylocsec_" + roi_types(i);
    end

    fig_path = fullfile(p,fig_name);
    begonia.path.make_dirs(fig_path)
    print(fig,fig_path,'-r300', '-dpng');
    delete(fig)

    %% output table by roi type
    outab = table(horzcat(CI_rMI(i,:))',pval(i,:)','VariableNames',["MI 95% CI", "pval"],'RowNames',string(loc_selc));

    tabname = "/tab/" + roi_types(i) + "_" + loc_state + "_MI_by_sec.xlsx";
    tabpath = fullfile(p,tabname);
    begonia.path.make_dirs(tabpath)
    writetable(outab,tabpath,'WriteRowNames',true)
end
end