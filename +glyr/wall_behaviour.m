function [no_trans, trans] = wall_behaviour(tss)
% find the tseries that change from still to locomotion(run/motion) when
% the wall approaches the whiskers
import begonia.data_management.multitable.*
import begonia.logging.*
no_trans = [];
trans = [];
for ts = tss
    log(1,"Loading multitab from " + ts.name)
    tab = ts.load_var('multitab');
    dt = unique(tab.trace_dt);
    tab_loc = tab.trace{tab.category == "locomotion"};
    tab_whisk = tab.trace{tab.category == "whisking"};
    tab_loc(tab_loc == "Still" & tab_whisk) = "Still-Whisking";
    tab_loc = string(tab_loc);
    tab = tab(tab.category == "ca-roi-dff",:);
    
    % find start of stimulation
    trial = glyr.rig.get_trials(ts);
    trial = trial{:};
    if trial.has_var("whisker_log")
        whisker = trial.load_var("whisker_log");
        wall_start = whisker.start;
        %         wall_in = whisker.estimated_start;
        %         wall_out = whisker.stop;
        wall_start_idx = seconds(round(wall_start/dt));
        %         wall_in_idx = seconds(round(wall_in/dt));
        %         wall_out_idx = seconds(round(wall_out/dt));
        pre_s = wall_start - seconds(3.5);
        pre_e = wall_start - seconds(0.5);
        dur_s = wall_start;
        dur_e = wall_start + seconds(3);
        post_s = dur_e + seconds(1);
        post_e = post_s + seconds(3);
    end
    
    % Check that the mouse is moving ('run' or 'motion') during the
    % transition to stimulation (at least 40% should br run/motion)
    log(1,"Checking for locomotion state...")
    stim = wall_start_idx:wall_start_idx + 2/dt;
    if ~any(tab_loc(stim) == "Transition_still_motion")
        no_trans = [no_trans,ts];
        pre_n(length(no_trans)) = {tab_loc(wall_start_idx - 2/dt: wall_start_idx)};
        dur_n(length(no_trans)) = {tab_loc(stim)};        
        c = pre_n{length(no_trans)};
        n_pre_behav(length(no_trans)) = most_common(c);
        d = dur_n{length(no_trans)}; 
        n_dur_behav(length(no_trans)) = most_common(d);              
    else
        trans = [trans,ts];
        pre(length(trans)) = {tab_loc(wall_start_idx - 2/dt: wall_start_idx)};
        dur(length(trans)) = {tab_loc(stim)};
        c = pre{length(trans)};
        pre_behav(length(trans)) = most_common(c);
        d = dur{length(trans)}; 
        dur_behav(length(trans)) = most_common(d);     
    end
end
name = {'TSeries','mouse','FoV','pre_trace','stim_trace','pre','stim'};
no_trans = table(string({no_trans.name})',string(no_trans.load_var('mouse'))',...
    string(no_trans.load_var('RFOV'))',pre_n',dur_n',...
    n_pre_behav',n_dur_behav','VariableNames',name);
trans = table(string({trans.name})',string(trans.load_var('mouse'))',...
    string(trans.load_var('RFOV'))',pre',dur',...
    pre_behav',dur_behav','VariableNames',name);
end


function out =  most_common(trace)
[s,~,j] = unique(trace);
out = string(s{mode(j)});
end