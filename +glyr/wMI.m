function wMI(mtab,do_by_entity,do_max,still_secs,do_plots,do_save)
if nargin < 5, do_save = false; end 
if nargin < 5, do_plots = false; end 
if nargin < 4, still_secs = 4; end % still segment minimum length
if nargin < 3, do_max = false; end
if nargin < 2, do_by_entity = false; end

exp_state_comb = ["Baseline","Baseline";"Stimulation","Stimulation";...
    "Baseline", "Stimulation"; "Baseline", "Stimulation"];
whisk_comb = ["Still","Still-Whisking";"Still","Still-Whisking";...
    "Still","Still";"Still-Whisking","Still-Whisking"];

roi_types = unique(mtab.roi_type);
roi_types(roi_types == "ND") = [];
roi_types(roi_types == "Gp") = [];
mtab(mtab.category == "spikes_prob",:) = [];
for j = 1:length(roi_types)
    for i = 1:size(exp_state_comb,1)
        glyr.whisking_MI(mtab,do_by_entity,do_max,exp_state_comb(i,1),whisk_comb(i,1),...
            exp_state_comb(i,2),whisk_comb(i,2),roi_types(j),do_plots,0,do_save,...
            still_secs);
    end
end
end