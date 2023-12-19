function plot_speed_vs_states(tss,do_fig,do_save)
% Plot the speed trace and the locomotion states to compare how well the
% segmentation is done
if nargin < 3, do_save = false; end
if nargin < 2, do_fig = true; end
if do_save, path = uigetdir; end
for ts = tss
    trial = glyr.rig.get_trials(ts);
    trial = trial{:};
    speed = trial.load_var("speed");
    loc = trial.load_var("locomotion_tab");
    
    ep_name = categorical(["Still","Transition_still_motion",...
        "Motion","Run","Transition_motion_still"])';
    color = glyr.plot.brewermap(5,'Paired');
    % color = num2cell(c,2);
    
    color_tab = table(ep_name,color);
    % innerjoin(loc,color_tab)
    if do_fig
        fig = figure;
    end
    p = plot(speed,'Color',[0.2 0.2 0.2],'LineWidth',1.5);
    hold on
    h = yucca.plot.plot_episodes(loc.locomotion_state,loc.start_sec,loc.end_sec,...
        0.7,[],color_tab);
    
    l = legend([p,h],"Speed",h.DisplayName);
    l.Location = 'southoutside';
    l.NumColumns = 6;
    l.Box = 'off';
    axis tight
    xlabel('Time (sec)')
    ylabel('deg/s')
    title('Speed vs Locomotion state')
    
    if do_save
        filename_signal = "Speed_vs_LocomotionState " + ts.name;
        outpng_1 = fullfile(path, [char(filename_signal) '.png']);
        print(fig, outpng_1, '-r300', '-dpng');
        % clean up:
        delete(fig)
    end
end
end