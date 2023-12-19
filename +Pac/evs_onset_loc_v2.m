function [event_onset,evs_out] = evs_onset_loc_v2(tss,dt,...
    do_convert,do_plots,do_save,do_remove,only_first,do_cut, plot_by_row)
% Events onset during transition to locmotion. Bin the events' onset of the
% different transitions, individually.
% outputs:
% - event_onset --> containers map that contains the table with the event
%                   onset distribution for each roi type (keys)
% - evs_out --> nested cell array (roi types) with the event onset in
%               frames
if nargin < 9, plot_by_row = []; end % plot active roi in separate rows
if nargin < 8, do_cut = true; end % cut transition to 6s
if nargin < 7, only_first = false; end % select only the first roi trans event
if nargin < 6, do_remove = false; end % remove transitions with less thas 'min_nrios' rois
if nargin < 5, do_save = false; end
if nargin < 4, do_plots = false; end
if nargin < 3, do_convert = false; end % convert events to events rate
if nargin < 2, dt = 0.25; end % time binning (group events occurrence)

% get transtions tabs
gen = string(tss.load_var('genotype'));
fs = 10;
n = 0;
tab = cell(1,length(tss));
for ts = tss
    n = n +1;
    if ts.has_var("transtab")
        tab{n} = ts.load_var("transtab");
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

% Binned time vector
time_bins = -3:0.25:max(tab.trans_length)/fs + 1;

% Create events table by roi type
rois_type = unique(tab.roi_type(~ismissing(tab.roi_type)));
nrois_type = numel(rois_type);
events_tab = cell(1,nrois_type);
events_rate_tab = cell(1,nrois_type);
evs_out = cell(1,nrois_type);
for j = 1:nrois_type
    tab_r = tab(tab.roi_type == rois_type(j),:);
    total_trans = numel(unique(tab_r.trans_id));
    roi_type = rois_type(j);
    events_on = nan(total_trans,numel(time_bins));
    tr_id = unique(tab_r.trans_id,'stable');
    nrois = zeros(total_trans,1);
    active = zeros(total_trans,1);
    trans_id = strings(total_trans,1);
    mouse = strings(total_trans,1);
    tserie = strings(total_trans,1);

    % By different transition id
    for i = 1:total_trans
        t = tab_r(tab_r.trans_id == tr_id(i),:);
        nrois(i) = height(t);
        active(i) = sum(t.total_events > 0);
        trans_id(i) = unique(t.trans_id);
        mouse(i) = unique(t.mouse);
        tserie(i) = unique(t.tseries);
        n_secs = ceil(unique(t.trans_length)/fs);

        % fill with zeros transitions with inactive rois
        if active(i) == 0
            events_on(i,1:3/dt+1 + n_secs/dt) = 0;
            evs_out{j}(i) = cell(1);
        else

            % events onset
            evs = cellfun(@find,t.events,'UniformOutput',false);
            if only_first
                % take only first event of each roi

                % first look fot event that occur from the trans2loc
                ev_idx_1 = cellfun(@(s) find(s >= 2*fs,1,'first'),evs,...
                    "UniformOutput",false);

                % if not found, look for events in the previous sec
                ev_idx_2 = cellfun(@(s) find(s >= fs,1,'first'),evs,...
                    "UniformOutput",false);
                evs_idx_m  = cellfun(@isempty,ev_idx_1);
                ev_idx_1(evs_idx_m) =  ev_idx_2(evs_idx_m);

                evs = cellfun(@(s,g) s(g), evs,ev_idx_1,'UniformOutput',false);

                % if no events fall within that time, remove
                if all(cellfun(@isempty,evs))
                    active(i) = 0;
                    events_on(i,1:3/dt+1 + n_secs/dt) = 0;
                    evs_out{j}(i) = cell(1);
                    continue
                end
            end

            if plot_by_row
                evs_out{j}(i) = {sort([evs{:}])};
            else
                evs_out{j}(i) = {evs};
            end


            % subrtact before transition seconds
            ee = cellfun(@(s) s - 3*fs,evs,'UniformOutput',false); % 3 --> 2
            ee = [ee{:}]/fs;

            % bin event in time intervals (dt bins)
            ee(ee > 0) = ceil(ee(ee > 0)*1/dt)/(1/dt);
            ee(ee < 0) = floor(ee(ee < 0)*1/dt)/(1/dt);
            ee(ee == 0) = dt;
            ev_on = arrayfun(@(s) ismember(time_bins(1:3/dt+1 +...
                n_secs/dt),s),ee,'UniformOutput',false);
            evvss = vertcat(ev_on{:})';
            evon = sum(evvss,2);
            events_on(i,1:length(evon)) = evon';
        end
    end

    % Create table
    evs_tab = table(mouse,tserie,trans_id,nrois,active);
    evs_t = array2table(events_on,"VariableNames",string(time_bins));
    events_tab{j} = [evs_tab,evs_t];

    % remove trnasition with no active rois
    if do_remove
        min_nrois = 1;
        events_tab{j}(events_tab{j}.active < min_nrois,:) = [];
    end

    % Convert events to events rate (depends on n active rois)
    if plot_by_row
        rois_evs = vertcat(evs_out{j});
        valid_trans_idx = ~cellfun(@isempty,rois_evs);
        rois_evs = rois_evs(valid_trans_idx);
        valid_trans = trans_id(valid_trans_idx);
        loc_dur = zeros(1,length(valid_trans));
        for v = 1:length(valid_trans)
            loc_dur(v) = unique(tab_r.trans_length(tab_r.trans_id ==...
                valid_trans(v)),'stable');
        end

        % mice
        mice = unique(tab_r.mouse(ismember(tab_r.trans_id,valid_trans)),...
            'stable');

        % speed
        sp = tab(ismember(tab.trans_id,valid_trans),:);
        speed = sp(sp.seg_category == "speed",:);
        sp_loc = cellfun(@(s) mean(s(3*fs:end-1*fs),'omitnan'),speed.trans);

        % number of active rois per transition
        n_trans_reps = cellfun(@length,rois_evs)';

        rois_evs = horzcat(rois_evs{:})';

        % clone trans id name and trans duration (as many as active rois)
        ids_rep = arrayfun(@(s,g) repmat(s,g,1),valid_trans,n_trans_reps,...
            'UniformOutput',false);
        ids = vertcat(ids_rep{:});
        [~,yint,yintl] = unique(ids,'stable');

        loc_dur = arrayfun(@(s,g) repmat(s,g,1),loc_dur,n_trans_reps',...
            'UniformOutput',false);
        loc_dur = vertcat(loc_dur{:});

        % sort by event onset (reorder transitions)
        [rois_evs,sort_idx] = sort(rois_evs,'ascend');
        loc_dur = loc_dur(sort_idx);
        yintl = yintl(sort_idx);

        % limit transitions to 6 sec
        if do_cut
            mx_trans_sec = max(loc_dur);
            loc_dur(loc_dur > 6*fs) = 6*fs;

            % eliminate evs onset > 9s
            rmv_idx = rois_evs > 9*fs;  %its 9 because id adds the 3s pre locomoition
            rois_evs(rmv_idx) = [];
            loc_dur(rmv_idx) = [];
            yintl(rmv_idx) = [];
        end

        % Plot by row
        fig = figure('Position',[291 59 1560 918]);

        matrx = zeros(length(rois_evs),round(mx_trans_sec));
        for e = 1:length(rois_evs)
            matrx(e,rois_evs(e)) = 1;
        end

        subplot(1,4,1:2)
        imagesc(matrx)
        colorbar

        % mark transition
        xline(2*fs,'LineWidth',2,"Color",'r')
        xline(3*fs,'LineWidth',2,"Color",'r')

        % empty secs line width (end of locomotion)
        if do_remove, w = 8; else, w = 4;end

        % mark end of locomotion
        hold on
        for i = 1:length(loc_dur)
            xx = loc_dur(i) + 3*fs;
            line([xx mx_trans_sec],[i i],'LineWidth',8,'Color','k')
        end

        yticklabels(yintl)
        xticklabels(xticks/fs - 3)
        xlabel("Time (sec)")
        ylabel("n trans")
        title(roi_type + " Events onset during trans to Locomotion in "...
            + ".Total trans: " + numel(valid_trans) + ". Mice: " +...
            numel(mice))

        % Plot event onset boxplot
        subplot(1,4,3)
        boxchart(rois_evs/fs - 3)
        hold on
        spread = 0.5; % 0=no spread; 0.5=random spread within box bounds (
        plot(rand(size(rois_evs))*spread -(spread/2) + 1, rois_evs/fs - 3, 'ro')

        title("Events onset lag from Locomotion")
        xticklabels("Events")
        ylabel("lag(sec)")

        subplot(1,4,4)
        boxchart(sp_loc)
        hold on
        plot(rand(size(sp_loc))*spread -(spread/2) + 1, sp_loc, 'ro')

        %         plot(rand(numel(sp_loc),1)*spread,sp_loc,'ro')
        title("Mean Speed")
        ylabel("speed cm.s-1")
    else
        if do_convert
            e_t = events_tab{j};
            idx = e_t.active ~= 0;
            evs_rate = e_t{:,7:end};
            evs_rate(idx,:) = evs_rate(idx,:)./e_t.active(idx);
            e_t{:,7:end} = evs_rate;
            events_rate_tab{j} = e_t;
            if do_remove
                if rois_type(j) == "AE", min_nrois = 1; else, min_nrois = 3; end
                events_rate_tab{j}(events_rate_tab{j}.active < min_nrois,:) = [];
            end
            % plot events ratio
            if do_plots
                plot_events(events_rate_tab{j},time_bins,roi_type,exp_state,...
                    do_save,virus,drug,do_convert,do_remove)
            end
        else
            % plot events
            if do_plots
                plot_events(events_tab{j},time_bins,roi_type,exp_state,do_save...
                    ,virus,drug,do_convert,do_remove)
            end
        end
    end

    % Save table (events or events ratios)
    if do_save
        path = "/Volumes/GlyR/GlyR project/Plots/Events_transition_locomotion";
        if do_remove
            filtt = "filtered";
        else
            filtt = "all_trans";
        end

        folderpath = fullfile(path,filtt);
        if do_convert && ~plot_by_row
            n_ev = "/tab/Events_onset_rate_" + roi_type;
        else
            n_ev = "/tab/Events_onset_" + roi_type;
        end

        file_1 = fullfile(folderpath,n_ev);
        begonia.path.make_dirs(file_1)

        if do_convert && ~plot_by_row
            writetable(events_rate_tab{j},file_1,'FileType','spreadsheet')
        else
            writetable(events_tab{j},file_1,'FileType','spreadsheet')
        end

        if plot_by_row
            n_ev = "/plots/Events_onset_" + "_" + roi_type;
            f = fullfile(folderpath,n_ev);
            begonia.path.make_dirs(f)
            print(fig,f,'-r300',"-dpng")
            delete(fig)
        end
    end
end

% output
if do_convert
    event_onset = containers.Map(rois_type,events_rate_tab);
else
    event_onset = containers.Map(rois_type,events_tab);
end
end

function plot_events(events_tab,time_bins,roi_type,do_save,...
    virus,drug,do_convert,do_remove)
fig = figure;
events = events_tab{:,7:end};
imagesc(events)
colorbar
xticklabels(string(time_bins(xticks)))
hold on

% mark transition
xline(9,'LineWidth',2,"Color",'r')
xline(13,'LineWidth',2,"Color",'r')

% empty secs line width (end of locomotion)
if do_remove, w = 8; else, w = 4;end

% mark end of locomotion
for i = 1:height(events_tab)
    xx = find(ismissing(events_tab{i,:}),1);
    line([xx width(events_tab)],[i i],'LineWidth',w,'Color','k')
end

xlabel("Time (sec)")
ylabel("n trans")
title(roi_type + " Events onset during transition to locomotion")

if do_save
    path = "/Volumes/Xiaoyi1/PAC/Analysis/Events_trans2locomotion";
    if do_remove
        filtt = "filtered";
    else
        filtt = "all_trans";
    end
    folderpath = fullfile(path,virus,drug,filtt);
    if do_convert
        n_ev = "/plots/Events_onset_rate_" + "_" + roi_type;
    else
        n_ev = "/plots/Events_onset_" + "_" + roi_type;
    end
    f = fullfile(folderpath,n_ev);
    begonia.path.make_dirs(f)
    print(fig,f,'-r300',"-dpng")
    delete(fig)
end
end