function plot_activity_state(ts,do_gradient,do_figure)

% Plot the behaviour state as a heatmap (this is the locomotion + whisking
% state). In addition, point out the whisker stimulation start and stop

if nargin < 3, do_figure = true; end
if nargin < 2, do_gradient = true; end

%% Get multitable w/ locomotion & whisking traces from mtab
mtab = ts.load_var("multitab");
locomotion = mtab.trace{mtab.category == "locomotion"};
whisking = mtab.trace{mtab.category == "whisking"};

dt = unique(mtab.trace_dt);

%% Get start & stop whisker stimulaiton
%%% TBD. get the whisker information from the multitab so it is not necessary
% to get the trial
trial = glyr.rig.get_trials(ts);
trial = trial{:};
if trial.has_var("whisker_log")
    whisker = trial.load_var("whisker_log");
    wall_start =  seconds(whisker.start)/dt;
    wall_in = seconds(whisker.estimated_start)/dt;
    wall_out = seconds(whisker.stop)/dt;
end

%% Assign values to each locomotion/whisking state

% loc_state = double(locomotion);
% This can be used instead of assigning a number to each category manually
% (even if the category is not present in the vector, categories are saved
% when the vector was created. E.g. "Run" state is always 4, so when a trace
% that only includes "Run" is converted to double, it will be a vector
% of 4s, not 1s). But to make it more readable let's assign it manually

% n_states = numel(categories(locomotion));

loc_state = zeros(length(locomotion),1);
loc_state(locomotion == "Still") = 1;
loc_state(locomotion == "Still" & whisking) = 2;
loc_state(locomotion == "Transition_still_motion") = 3;
loc_state(locomotion == "Motion") = 4;
loc_state(locomotion == "Run") = 5;
loc_state(locomotion == "Transition_motion_still") = 6;

if do_gradient
    % transition to motion
    if any(loc_state == 3)
        trans_m = bwconncomp(loc_state == 3).PixelIdxList;
        for i = 1:length(trans_m)
            g = length(trans_m{i});
            loc_state(trans_m{i}) = 2:2/g:4-1/g;
        end
    end
    
    % transition to still
    if any(loc_state == 6)
        trans_s = bwconncomp(loc_state == 6).PixelIdxList;
        for i = 1:length(trans_s)
            g = length(trans_s{i});
            loc_state(trans_s{i}) = 4:-2/g:2+1/g;
        end
    end
    
    % Colorbar limits & labels
    c_lim = 5;
    colorbar_labels = {'Still','Still/whisking','Transition','Motion','Run'};
else
    c_lim = 6;
    colorbar_labels = {'Still','Still/whisking','Trans.Still-Motion',...
        'Motion','Run','Trans.Motion-Still'};
end

%% Plot activity sate
if do_figure
    figure
end

% Plot
% h = pcolor([activity;activity]);
imagesc(loc_state');
ax = gca;
ax.XTickLabel = round(double(string(ax.XTickLabel)) * dt,1);
ax.YColor = 'none';
title('Behaviour State')
axis tight
box off

% motion_cmap = [0.6,0.9,0.9];
% run_cmap = [0.4,0.6,1];
% still_w_cmap = [0.6,0.9,0.5];
% still_cmap = [0.8,0.9,0.8];
% cmap = [still_cmap;still_w_cmap;trans_m_cmap;motion_cmap];
% cmap_idx = ismember([1,2,3],loc_state);
% colormap(cmap(cmap_idx,:))
%h.AlphaData = 0.5;% FaceAlpha = 0.5;

% Define colormap characteristics (color,limits & labels)
trans_m_cmap = glyr.plot.colorGradient([0,0,0],[1,1,1],100);
%[0.3,1,0.2],[0.3,0.2,1]
colormap(trans_m_cmap)
caxis([1 c_lim])
tick = 1+0.5*(c_lim-1)/c_lim:(c_lim-1)/c_lim:c_lim;
colorbar('Ticks',tick,'TickLabels',colorbar_labels,'Box','off',...
    'Limits',[1 c_lim]);

% Add lines indicating start/end of whisker stimulation
hold on
xline(wall_start,'-r','LineWidth',2,'Label',"In")%'LabelOrientation','horizontal')
xline(wall_in,'-r','LineWidth',2,'Label',"Est. Start")%,'LabelOrientation','horizontal')
xline(wall_out,'-r','LineWidth',2,'Label',"Out")%,'LabelOrientation','horizontal')
hold off
end

% Old version
% run = traces_1.trace{traces_1.category == "running"};
% whisk = traces_1.trace{traces_1.category ~= "running"};
% whisk(1) = whisk(2);
% run(1) = run(2);
% still = ~run;
% still_whisk = still & whisk;
% still_no_whisk = still & ~ whisk;
%
% run_frames = bwconncomp(run).PixelIdxList;
% still_whisk_frames = bwconncomp(still_whisk).PixelIdxList;
% still_no_whisk_frames =  bwconncomp(still_no_whisk).PixelIdxList;
% figure
% box off
% yticks([])
% hold on
% title("Activity state")
% plot_frames = (@(s,c) cellfun(@(s) area([s(1)-1,s(end)],[1,1],'FaceAlpha',0.5,...
%     'EdgeColor','none','FaceColor',c,'AlignVertexCenters','on'),s));
% p_run = plot_frames(run_frames,'b');
% p_still_w = plot_frames(still_whisk_frames,'g');
% p_still = plot_frames(still_no_whisk_frames,'r');
%
% legend([p_run(1),p_still_w(1),p_still(1)],"Run/Whisking",...
%     "Still/Whisking","Still",'Location','northeastoutside')
% axis tight
