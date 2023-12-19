function rMI(mtab,do_combine,method,still_secs,loc_secs,loc_selection,...
    do_exclusive,excl_loc,mmnt,do_plots,do_save)
if nargin < 11, do_save = false; end
if nargin < 10, do_plots = false; end
if nargin < 9, mmnt = "no_comb"; end
if nargin < 8, excl_loc = "Motion"; end
if nargin < 7, do_exclusive = false; end
if nargin < 6, loc_selection = "all"; end % seconds selection (1 = 1:30,2 = [31:60]...)
if nargin < 5, loc_secs = 5; end % locomotion segment minimum length
if nargin < 4, still_secs = 4; end % still segment minimum length
if nargin < 3, method = "entire"; end
if nargin < 2, do_combine = false; end


roi_types = unique(mtab.roi_type);
roi_types(roi_types == "ND") = [];
mtab(mtab.category == "spikes_prob",:) = [];

for j = 1:length(roi_types)
    if ~do_combine
        % Run
        Pac.running_MI(mtab,method,"Still","Run",roi_types(j),...
            do_plots,do_save,still_secs,0,0,loc_secs,loc_selection,do_exclusive);

        % Motion
        Pac.running_MI(mtab,method,"Still","Motion",roi_types(j),do_plots,do_save,...
            still_secs,0,0,loc_secs,loc_selection,do_exclusive);
    else
        % Run-Motion combined
        Pac.running_MI(mtab,method,"Still","Motion",roi_types(j),do_plots,...
            do_save,still_secs,1,0,loc_secs,loc_selection,do_exclusive,excl_loc,mmnt);
    end
end
end