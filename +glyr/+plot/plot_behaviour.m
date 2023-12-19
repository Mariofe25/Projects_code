function [fig,ll] = plot_behaviour(tss,do_fig,do_save)
% Plot the speed trace and the locomotion states to compare how well the
% segmentation is done
if nargin < 3, do_save = false; end
if nargin < 2, do_fig = true; end
if do_save, path = uigetdir; end
for ts = tss                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    mtab = ts.load_var('multitab');
    %     trial = glyr.rig.get_trials(ts);
    dt = unique(mtab.trace_dt);
    speed = mtab.trace{mtab.category == "speed"};
    
    % Convert speed trace to cm/s (v = r*w)(w in rad/s)
    r = 0.08; % 8 cm (in m)
    speed = r * 0.017453 * speed * 100; %cm/s
   
    
    %     loc = trial.load_var("locomotion_tab");
    
    whisker = mtab.trace{mtab.category == "whisker"};
    %     w_tab = trial.load_var("whisking_tab");
    
    if any(mtab.category == "pupil_ratio")
        pupil = mtab.trace{mtab.category == "pupil_ratio"};
        do_pupil = true;
    else
        do_pupil = false;
    end
    
    loc = mtab.trace{mtab.category == "locomotion"};
    w = mtab.trace{mtab.category == "whisking"};
    
    loc(loc == "Still" & w) = "Still-Whisking";
    
    % Still-Whisking state
    loc_type = double(loc);
    loc_change = find(ischange(loc_type));
    
    ep_name = [loc(1);loc(loc_change)];
    start_frame = [1;loc_change];
    end_frame = [loc_change - 1;length(loc)];
    deltat = repmat(dt,numel(ep_name),1);
    start_sec = (start_frame * dt) - dt;
    end_sec = (end_frame * dt) - dt;
    sec_duration = end_sec - start_sec;
    
    behav = table(ep_name ,start_frame,end_frame,deltat,...
        start_sec,end_sec,sec_duration);
    
    ep_name = categorical(["Still","Still-Whisking","Transition_still_motion",...
        "Motion","Run","Transition_motion_still"])';
    color = glyr.plot.brewermap(6,'Paired');
    % color = num2cell(c,2);
    
    color_tab = table(ep_name,color);
    % innerjoin(loc_tab,color_tab)
    if do_fig
        fig = figure;
    else
        fig = gcf;
    end
%     ax = gca;
    title("Behaviour State " + ts.name)
    yyaxis left
    p1 = plot(0:dt:length(speed)*dt - dt,speed,'Color',[0.2 0.2 0.2],'LineWidth',1.5);
    xlabel('Time (sec)')
    ylabel('Speed cm/s')
    hold on
    h = yucca.plot.plot_episodes(behav.ep_name,behav.start_sec,behav.end_sec,...
        0.6,[],color_tab);
    yyaxis right
    p2 = plot(0:dt:length(speed)*dt - dt,whisker,'Color',[0.5 0.2 0.1],'LineWidth',1);
    ylim([0 max(whisker)* 2])
    ylabel('Whisking a.u')
    
    ll = [p1,p2,h];
    
    l = legend(ll,"Speed","Whisking",h.DisplayName);
    %     l.Location = 'southoutside';
    %     l.NumColumns = 8;
    %     l.Box = 'off';
    
    if do_pupil
        glyr.util.addaxis6.addaxis(0:dt:length(speed)*dt - dt,pupil,'-m',...
            'LineWidth',1.5)
        glyr.util.addaxis6.addaxisset([0.3 1],2)
        glyr.util.addaxis6.addaxislabel(2,'pupil ratio');
       
    end
    
    
    if do_save
        filename_signal = "Behaviour_State_ " + ts.name;
        outpng_1 = fullfile(path, [char(filename_signal) '.png']);
        print(fig, outpng_1, '-r300', '-dpng');
        % clean up:
        delete(fig)
    end
end
end