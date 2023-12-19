function plot_whisking_vs_states(tss,do_fig,do_save)
% Plot the speed trace and the locomotion states to compare how well the
% segmentation is done
if nargin < 3, do_save = false; end
if nargin < 2, do_fig = true; end
if do_save, path = uigetdir; end
for ts = tss
    trial = glyr.rig.get_trials(ts);
    trial = trial{:};
    whisker = trial.load_var("whisking_trim");
    w_tab = trial.load_var("whisking_tab");
    
    % Colormap states
    ep_name = categorical(["No Whisking", "Whisking","Uncertain"])';
    color = glyr.plot.brewermap(3,'Paired');
    color_tab = table(ep_name,color);
    % innerjoin(loc,color_tab)
    if do_fig
        fig = figure;
    end
    p = plot(whisker,'Color',[0.5 0.2 0.1],'LineWidth',1);
    hold on
    h = yucca.plot.plot_episodes(w_tab.whisk_state,w_tab.start_sec,w_tab.end_sec,...
        0.7,[],color_tab);
    
    l = legend([p,h],"Whisking",h.DisplayName);
    l.Location = 'southoutside';
    l.NumColumns = 4;
    l.Box = 'off';
   
    
    axis tight
    xlabel('Time (sec)')
    ylabel('a.u')
    title('Whisking vs Whisking state')
    hold off
    if do_save
        filename_signal = "Whisking_vs_WhiskingState " + ts.name;
        outpng_1 = fullfile(path, [char(filename_signal) '.png']);
        print(fig, outpng_1, '-r300', '-dpng');
        % clean up:
        delete(fig)
    end
end
end