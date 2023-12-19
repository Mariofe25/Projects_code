function [trs,tab] = get_trans2stim_data(tss,state,base_sec,stim_sec)
% select the tseries where the mouse is running/moving or still during the
% transition to Stimulation period.
% tab is the multitable with the selected data
if nargin < 4, stim_sec = 5; end
if nargin < 3, base_sec = 2; end
if nargin < 2, state = "Run"; end % "Still", "All"
import begonia.data_management.multitable.*
import begonia.logging.*
r = 0;
is_valid = false(1,numel(tss));
no_glyr = glyr.get_negative_glyr_ns(tss);
for ts = tss
    r = r + 1;
    log(1,"Loading multitab from " + ts.name)
    tab = ts.load_var('multitab');
    dt = unique(tab.trace_dt);
    tab_loc = tab.trace{tab.category == "locomotion"};
    tab_whisk = tab.trace{tab.category == "whisking"};
    tab_loc(tab_loc == "Still" & tab_whisk) = "Still-Whisking";
    tab_loc = string(tab_loc);
    tab_exp_state = tab.trace{tab.category == "exp_state"};
    tab = tab(tab.category == "ca-roi-dff" | tab.category == "speed" | ...
        tab.category == "pupil_ratio",:);
    
    start_stim = find(tab_exp_state == "Stim",1,'first');
    
    % trace x sec to the stim start and x sec from it
    idx_chunk = start_stim - base_sec/dt:start_stim + stim_sec/dt - 1;
    
    idx(r) = numel(idx_chunk);
    
    % Check that the mouse is moving ('run' or 'motion') during the
    % transition to stimulation
    log(1,"Checking for locomotion state...")
    if state == "Run"
%         is_valid(r) = all(tab_loc(idx_chunk) == "Run" |...
%             tab_loc(idx_chunk) == "Motion");

         is_valid(r) = sum(tab_loc(idx_chunk) == "Run" |...
             tab_loc(idx_chunk) == "Motion")> 0.6*length(tab_loc(idx_chunk));


    elseif state == "Still"
        is_valid(r) = all(tab_loc(idx_chunk) == "Still");
    else
        is_valid(r) = 1;
    end
    
    if is_valid(r)
        runtab{r} = timerange(tab,round(seconds(idx_chunk(1)*dt)),...
        round(seconds(idx_chunk(end)*dt)));
    else
        runtab{r} = {};        
    end
end
trs = tss(is_valid);
runtab(cellfun(@isempty,runtab)) = [];

tab = vertcat(runtab{:});
tab(tab.roi_type == "Gp",:) = [];
tab(tab.roi_type == "ND",:) = [];

% remove negative glyr NS in the IVM recordings
if ~isempty(no_glyr)
    nope = ismember(tab.roi_short_name,no_glyr);
    tab(nope,:) = [];       
end

log(1,"Done!")
end