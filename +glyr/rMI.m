function rMI(mtab,do_by_entity,do_combine,method,still_secs,loc_secs,...
    loc_selection,do_exclusive,excl_loc,mmnt,do_plots,do_save)
if nargin < 9, do_save = false; end
if nargin < 9, do_plots = false; end
if nargin < 8, mmnt = "no_comb"; end
if nargin < 9, excl_loc = "Motion"; end
if nargin < 8, do_exclusive = false; end
if nargin < 7, loc_selection = "all"; end % seconds selection (1 = 1:30,2 = [31:60]...)
if nargin < 6, loc_secs = 5; end % locomotion segment minimum length
if nargin < 5, still_secs = 4; end % still segment minimum length
if nargin < 4, method = "entire"; end
if nargin < 3, do_combine = false; end
if nargin < 2, do_by_entity = false; end
exp_state_comb = ["Baseline","Baseline";"Stimulation","Stimulation";...
    "Baseline", "Stimulation"; "Baseline", "Stimulation"];
run_comb = ["Still","Run";"Still","Run";"Still","Still";"Run","Run"];
motion_comb = ["Still","Motion";"Still","Motion";"Still","Still";"Motion","Motion"];

roi_types = unique(mtab.roi_type);
roi_types(roi_types == "ND") = [];
roi_types(roi_types == "Gp") = [];
mtab(mtab.category == "spikes_prob",:) = [];
for j = 1:length(roi_types)
    for i = 1:size(exp_state_comb,1)
        if ~do_combine

            % Run
            glyr.running_MI(mtab,do_by_entity,method,exp_state_comb(i,1),run_comb(i,1),...
                exp_state_comb(i,2),run_comb(i,2),roi_types(j),do_plots,do_save,...
                still_secs,0,0,loc_secs,loc_selection,do_exclusive);

            % Motion
            glyr.running_MI(mtab,do_by_entity,method,exp_state_comb(i,1),motion_comb(i,1),...
                exp_state_comb(i,2),motion_comb(i,2),roi_types(j),do_plots,do_save,...
                still_secs,0,0,loc_secs,loc_selection,do_exclusive);
        else

            % Run-Motion combined
            glyr.running_MI(mtab,do_by_entity,method,exp_state_comb(i,1),motion_comb(i,1),...
                exp_state_comb(i,2),motion_comb(i,2),roi_types(j),do_plots,do_save,...
                still_secs,1,0,loc_secs,loc_selection,do_exclusive,excl_loc,mmnt);
        end
    end
end
end