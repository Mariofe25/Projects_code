function events_on = transition2locomotion(tss,exp_state,do_save)
% get all the transition to locomotion
% 1- heatmap of the events onset in the differetn transitions(limited to
% 6sec locomotion)
% 2- Correlation speed and acceleration with events onset, rate active rois
% and max event
% 3- Correlation pupil ratio with events onset, rate active rois
% and max event

%% get rois onsets
virus = unique(string(tss.load_var('virus')));
drug = string(unique(tss.load_var('drug')));
fs = 30;
n = 0;
tab = cell(1,length(tss));
for ts = tss
    n = n +1;
    if ts.has_var("transtab_" + exp_state + "_pup")
        tab{n} = ts.load_var("transtab_" + exp_state + "_pup");
    else
        tab{n} = {};
    end
end
tab(cellfun(@isempty,tab)) = [];
tab = vertcat(tab{:});

% Filter table by length of run/motion part (trans_end - trans_start)
tab.trans_length =  cellfun(@length,tab.trans_idx);
tab.trans_length = tab.trans_length - 3*fs; % 3 --> before(2sec) + trans (1sec)
tab = sortrows(tab,'trans_length');

if ~any(tab.glyr_expression)
    drug  = drug + "_no-glyr";
end

% Split tab by roi type
rois_type = unique(tab.roi_type(~ismissing(tab.roi_type)));
for r = 1:numel(rois_type)
    % select by roi type
    roi_type = rois_type(r);
    tab_r = tab(tab.roi_type == roi_type,:);

    % number of mice
    n_mouse = unique(tab_r.mouse);

    % number of transitions
    n_trans = unique(tab_r.trans_id);

%     % ratio active rois per transition
%     for i = 1:length(n_trans)
%         ntran = tab_r.total_events(tab_r.trans_id == n_trans(i));
%         rois(i) = numel(ntran);
%         active_rois(i) = sum(ntran > 0,1,"omitnan");
%         rois_ratio(i) = active_rois(i)/rois(i);
%     end

%     rois_inf{r} = table(n_trans,rois',active_rois',rois_ratio',...
%         'VariableNames',["trans_id", "total_rois","active_rois","ratio_rois"]);


    % Select only rois with events
    tab_ra = tab_r(tab_r.total_events > 0,:);

    % Get the first event within the first 6s of locomotion, if not look in
    % the pre locomotion segement
    % *** In some cases event onset is delayed because there is not enough
    % *** pre-locmotion frames (filled withnans). Need it for the plot
    % *** real_eidx is the real event onset (need for finding theright ev onset)
    eidx = cellfun(@(f) find(f,1,'first'),tab_ra.events) - 1;
    elidx = cellfun(@(f) find(f(90:end),1,'first'),tab_ra.events,...
        'UniformOutput',false);
    qevs = find(eidx < 90);
    for i = 1:numel(qevs)
        if ~isempty(elidx{qevs(i)})
            eidx(qevs(i)) = elidx{qevs(i)} + 90 - 1;
        end
    end

%     % *** Calculate correct event lag onset
%     reidx = eidx;
%     for i = 1:length(eidx)
%         if isnan(tab_ra.trans_start_idx(i))
%             errs = find(~isnan(tab_ra.trans_idx{i}),1,'first');
%             reidx(i) = eidx(i) - errs;
%         end
%     end

    % Maximum first event and time to max Ca2+
    for i = 1:height(tab_ra)
        if tab_ra.total_events(i) == 1
            ee = tab_ra.evs{i};
        else
            [~, evidx] = min(abs([tab_ra.evs{i}.x_start_idx] - eidx(i)));
            ee = tab_ra.evs{i}(evidx);
        end
        tab_ra.event_max(i) = ee.y;
        tab_ra.event_dur(i) = ee.width;
        tab_ra.event_evon2peak(i) = ee.x - ee.x_start;
        tab_ra.event_locon2peak(i) = ee.x - ee.x_start + (eidx(i)/fs -3);
    end

    % sort events by event occurence
    [~, s] = sort(eidx);
    tab_ra1 = tab_ra(s,:);

    % remove rois (and transitions) with first event onset after 9 sec
    % (3 pre + 6 loc = 270 frames)
    tr_dur = 270;
    eidx = eidx(s);
    tab_ra1(eidx > tr_dur,:) = [];
    eidx(eidx > tr_dur) = [];

    % get roi traces for heatmap
    % dummy mat
    mat = nan(height(tab_ra1),tr_dur);
    for i = 1:height(tab_ra1)
        if length(tab_ra1.events{i}) < tr_dur
            yy = 1:length(tab_ra1.events{i});
        else
            yy = 1:tr_dur;
        end
        mat(i,yy) = tab_ra1.trans{i}(yy);
    end

    % store events onset of each roi type (for table and boxplots)
    events_on{r} = eidx/fs - 3;

    %% Plot rois onset
    fig = figure("Position",[51 524 1835 453]);

    %----
    % heatmap of ∆F/F of transitions traces
    subplot(1,4,1:2)
    imagesc(mat)
    title("Events onset during transition to locomotion in " + exp_state)
    xlabel("Time (sec)")
    ylabel("n rois")
    caxis([0 1])
    colorbar
    hold on

    % mark locmotion onset
    xline(3*fs,'LineWidth',2,"Color",'r')

    % mark end of locomotion for each transition (some are less than 6 sec)
    loc_dur = cellfun(@length,tab_ra1.trans);
    for i = 1:length(loc_dur)
        if loc_dur(i) < tr_dur
            xx = [loc_dur(i),tr_dur];
            line([xx(1) xx(2)],[i i],'LineWidth',4,'Color',[0.5,0.5,0.5])
        end
    end

    % relabel x-axis (seconds)
    xticks(0:30:width(mat))
    xticklabels(xticks/fs - 3)

    % mark events onset
    plot(eidx,1:height(mat),'r|');

    %------
    % Distribution of events onset

    % Histogram by seconds
    % classify event transition onsetb  by secs (deciles)
    evson_sec = ceil(eidx/30)-3;
    preevs = evson_sec <= 0;
    evson_sec(preevs) = evson_sec(preevs) -1;

    subplot(1,4,3)
    a = histogram(evson_sec);
    title("Distribution events onset during transition to locomotion: " +...
        rois_type(r))
    ylabel("n rois")
    xlabel("Time (sec)")
    %---
    % Boxplot events onset
    subplot(1,4,4)
    boxchart(eidx/fs - 3,'MarkerStyle','none','Orientation','horizontal')
    title("Lag events onset during transition to locomotion")
    xlabel("Lag (sec)")
    hold on

    % visualize individual data points
    spread = 0.5; % 0=no spread; 0.5=random spread within box bounds (
    plot(eidx/fs - 3,rand(size(eidx))*spread -(spread/2) + 1, 'bo')
    %---
    if do_save
        path = "/Volumes/GlyR/GlyR project/Plots/Events_transition_locomotion";
        folderpath = fullfile(path,virus,drug);
        n_ev = "/plots/Events_onset_" + exp_state + "_" + roi_type;
        f = fullfile(folderpath,n_ev);
        begonia.path.make_dirs(f)
        print(fig,f,'-r300',"-dpng")
        print(fig,f,'-r300',"-depsc")
        delete(fig)
    end
end
end