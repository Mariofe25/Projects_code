function align_pupil_evs_v2(tss,do_collapse,sort_first,cut,pup2loc,do_save)
% Time difference between the pupil onset and the fisrt event of each roi
% during the transition to locomotion.
% It also summarized the pupil onset to/from locomotion onset

if nargin < 6, do_save  = false; end % events from the same transition n the same row in the heatmap
if nargin < 5, pup2loc = 2.5; end % max secs from/to Pon and LOCon.
if nargin < 4, cut = 10; end % cut transitions to max 10 sec. If empty, 
if nargin < 3, sort_first = false; end % If true sort heatmap by 1st event onset. If false, sort by transition duration
if nargin < 2, do_collapse = false; end

% align rois events to pupil onset
exp_state = ["Baseline","Stimulation"];

% roi types
glyr.util.roi_types;
virus = unique(string(tss.load_var('virus')));
drug = string(unique(tss.load_var('drug')));
fs = 30;
for i = 1:numel(exp_state)
    % get the transitionn rois event onset distribution in each experimental state
    [events,evs_f] = glyr.evs_onset_loc_v2(tss,exp_state(i),0.25,1,0,0,0);

    % get the pupil onset of each transition
    events_pup = glyr.pupil_trans2loc(tss,events,"all",exp_state(i));

    % save the table in a cell array
    ep{i} = events_pup;

    % align to pupil onset for each roi type. Only first event
    for j = 1:length(roi_type)
        tab = events_pup(roi_type(j));
        ee = evs_f{j};

        % eliminate transitions with Pon to/from LOCon greater than x sec
        % apart from each other
        if ~isempty(pup2loc)
            ee(abs(tab.pupil_onset) > pup2loc) = [];
            tab(abs(tab.pupil_onset) > pup2loc,:) = [];
        end
 
        pups = tab(:,{'mouse','fov','trans_id','pupil_onset_f'});

        x_sec = zeros(height(pups),1); % duration  transition
        ev_onset = cell(height(pups),1); % envent onset within each transition
        pup_ev_f = cell(height(pups),1); % events onset from pupil onset
        pup_ev_sec = cell(height(pups),1); % events onset from pupil onset (sec)
        pup2loc_f = zeros(height(pups),1); % pupil onset to locomotion onset (frames)
        pup2loc_sec = zeros(height(pups),1); % pupil onset to locomotion onset (sec)

        % transitions
        for k = 1:height(pups)
            x_sec(k) = find(ismissing(tab(k,:)),1);
            p_sec = pups.pupil_onset_f(k);
            rois = ee{k};
            if isempty(rois) || p_sec == 0
                ev_onset{k} = nan;
            else
                rois(cellfun(@isempty,rois)) = [];
                if any(cellfun(@length,rois) > 1)
                    ev_idx = cellfun(@(s) find(s >= p_sec,1,'first'),rois,...
                        "UniformOutput",false);
                    rois = cellfun(@(s,g) s(g), rois,ev_idx,'UniformOutput',false);
                    ev_onset{k} = [rois{:}]';
                else
                    rois = [rois{:}]';
                    % eliminate events that happen before Pon and
                    % LOCon
                    rois(rois < p_sec & rois < 3*fs + 10) = []; % +10 to give a bit of margin (0.3 sec)

                    if isempty(rois)
                        ev_onset{k} = nan;
                    else
                        ev_onset{k} = rois;
                    end
                end
            end
            
            % events onset to pupil onset 
            pup_ev_f{k} = ev_onset{k} - p_sec; 
            pup_ev_sec{k} = pup_ev_f{k}/fs;

            % pupil onset to locomotion onset
            pup2loc_f(k) = p_sec - 3*fs;
            pup2loc_sec(k) = pup2loc_f(k)/fs;
        end

        % remove transition w/o events (or events that happen before the
        % pupil onset
        nope = cellfun(@(s) any(isnan(s)),pup_ev_sec);
        pup2loc_f(nope) = [];
        pup2loc_sec(nope) = [];
        x_sec(nope) = [];
        mx_sec = max(x_sec);
        mt = double(string(tab.Properties.VariableNames(mx_sec)));
        dt = 0.25;
        time_bins = -3:dt:mt;
        time_bins_p = 0:dt:(mt + abs(min(pup2loc_sec)));

        pup_ev_f =  pup_ev_f(~nope);
        pup_ev_sec = pup_ev_sec(~nope);
        trans_id = pups.trans_id(~nope);

        % data for the table
        mouse = pups.mouse(~nope);
        fov =  pups.fov(~nope);
        type = repmat(roi_type(j),length(mouse),1);
        state = repmat(exp_state(i),length(mouse),1);
        loc_duration_s = time_bins(x_sec - 8)'; % -8 due to tab columns that are not trace columns
        pup2loc_onset = pup2loc_sec;
        cons_loc_duration = time_bins(x_sec - 8)';

         if ~isempty(cut)
            ct = cut/dt + 8 + 3/dt + 1;
            x_sec(x_sec > ct) = ct;
            dlt_evs = cellfun(@(d) d > cut,pup_ev_sec,'UniformOutput',false);
            pup_ev_sec = cellfun(@(s,d) s(~d),pup_ev_sec,dlt_evs,"UniformOutput",false);
            trans_dlt_idx = cellfun(@isempty,pup_ev_sec);
            pup_ev_sec(trans_dlt_idx) = [];
            x_sec(trans_dlt_idx) = [];
            trans_id(trans_dlt_idx) = [];
            pup2loc_sec(trans_dlt_idx) = [];
            cons_loc_duration = time_bins(x_sec - 8)';
            mouse(trans_dlt_idx) = [];
            fov(trans_dlt_idx) = [];
            type(trans_dlt_idx) = [];
            state(trans_dlt_idx) = [];
            loc_duration_s(trans_dlt_idx) = [];
            pup2loc_onset = pup2loc_sec;
        end

        outab = table(mouse,fov,type,state,loc_duration_s,cons_loc_duration,pup2loc_onset);
        evfpup = cell2table(pup_ev_sec,"VariableNames","roi");
        outab = [outab,evfpup];

        % plots (each transition in one row or rois within  a transition
        % in different rows
        if do_collapse
            % plot heatmap with event oset and locomotion onset (where
            % possible)
            [~,yint,yintl] = unique(trans_id,'stable');
            fig = plot_pupev(pup_ev_sec,dt,time_bins,yint,roi_type(j),exp_state(i),...
                x_sec,pup2loc_sec,time_bins_p,do_collapse,sort_first,yintl);
        else

            % each roi in a different row (even if it is from the same recording)
            n_trans_reps = cellfun(@length,pup_ev_sec)';

            ids_rep = arrayfun(@(s,g) repmat(s,g,1),trans_id',n_trans_reps,...
                'UniformOutput',false);
            ids = vertcat(ids_rep{:});
            [~,yint,yintl] = unique(ids,'stable');
            pup_ev_sec = cellfun(@sort,pup_ev_sec,'UniformOutput',false);
            xpos = vertcat(pup_ev_sec{:});
            yval = ones(length(ids),1);

            % also clone the pupil onset times and the end of locomotion index
            pup_on = arrayfun(@(s,g) repmat(s,g,1),pup2loc_sec',n_trans_reps,...
                'UniformOutput',false);
            pupon = vertcat(pup_on{:});

            f_stp = arrayfun(@(s,g) repmat(s,g,1),x_sec',n_trans_reps,...
                'UniformOutput',false);
            fstop = vertcat(f_stp{:});

            % plot heatmap with event oset and locomotion onset (where
            % possible)            
            fig = plot_pupev(xpos,dt,time_bins,yint,roi_type(j),exp_state(i),...
                fstop,pupon,time_bins_p,do_collapse,sort_first,yintl);
        end

        if do_save
            path = '/Volumes/GlyR/GlyR project/Plots/Events_pupil_onset';
            if do_collapse
                cll = "on_row";
            else
                cll = "multiple_rows";
            end
            folderpath = fullfile(path,virus,drug,cll);

            % save plots
            n_ev = "/plots/Events2Pupil_onset_" + exp_state(i) + "_" + roi_type(j);
            f = fullfile(folderpath,n_ev);
            begonia.path.make_dirs(f)
            print(fig,f,'-r300',"-dpng")
            delete(fig)

            % save tab
            n_t = "/tab/Events2Pupil_onset_" + exp_state(i) + "_" + roi_type(j);
            file_tab = fullfile(folderpath,n_t);
            begonia.path.make_dirs(file_tab)
            writetable(outab,file_tab,"FileType",'spreadsheet')
        end
    end
end

% get pupil onset to/from locomotion onset info
pupil_insight(ep,exp_state,do_save,virus,drug)
end

function fig = plot_pupev(xpos,dt,time_bins,yint,roi_type,exp_state,...
    fstop,pupon,time_bins_p,do_collapse,sort_first,yintl)

fig = figure("Position",[648 219 1840 1118]);
hold on
lyt = tiledlayout(1,2,'TileSpacing','compact');
title(lyt,roi_type + " ROIs event onsets")
ax1 = nexttile();
imagesc(ax1,zeros(length(pupon),length(time_bins)));

if sort_first
    [xpos,sort_idx] = sort(xpos,'ascend');
    pupon = pupon(sort_idx);
    fstop = fstop(sort_idx);
    yintl = yintl(sort_idx);
end

zr = find(time_bins == 0);
for p = 1:length(xpos)
    if do_collapse
        ll = cellfun(@length,xpos(p));
        for l = 1:ll
            imagesc(ax1,'XData',xpos{p}(l)/dt + zr,'YData',p,"CData",1)
        end
    else
        imagesc(ax1,'XData',xpos(p)/dt + zr,'YData',p,"CData",1)
    end
end

% pupil onset
xline(ax1,[zr zr],'LineWidth',2,'Color','k')
    
% locomotion onset and duration
for p = 1:length(xpos)    
    pon = pupon(p);
    xx = fstop(p);
    % tab n columns that do not belong to the trace
    nl = 8;

    % loc onset
    loc_x = zr  - pon/dt;
    line(ax1,[loc_x loc_x],[p-0.5 p+0.5],'LineWidth',4,'Color','r')

    % loc end
    start = xx - nl - (pon/dt);
    line(ax1,[start length(time_bins)],[p p],'LineWidth',8,'Color','k')
end

if sort_first
    yticks(ax1,1:length(yintl))
    yticklabels(ax1,yintl)
else
    yticks(yint)
    yticklabels(1:length(yint))
end
xticklabels(ax1,time_bins(xticks(ax1)))
ylabel(ax1,"n transitions")
xlabel(ax1,"Time (sec)")
title(ax1,"Pupil-Ca2+ event onset.RoI type: "  + roi_type +...
    ". " + exp_state + " . N trans: " + numel(unique(yintl)))

ax2 = nexttile();
clss = repmat(categorical("before"),length(xpos),1);
clss(pupon > 0) = "after";
boxchart(ax2,clss,xpos)
ylabel("lag (sec)")
title(ax2, "Comparison events onset lag. Pon before: " + ...
    numel(xpos(clss == "before")) + "  n rois vs Pon after " + ...
    numel(xpos(clss == "after")) + " n rois")
end

function pupil_insight(ep,exp_state,do_save,virus,drug)

for h = 1:length(ep)
    % get container with tables in each exp state
    pup_tab = ep{h};

    % get the tables
    data = pup_tab.values;
    data = vertcat(data{:});

    % get unique transitions and their  pupil onsets
    [trans{h},idx] = unique(data.trans_id,'stable');
    pup_on{h} = data.pupil_onset(idx);
    exp{h} = repmat(categorical(exp_state(h)),length(idx),1);
end

pupil_on = vertcat(pup_on{:});
state = vertcat(exp{:});
puptab = table(state,pupil_on);

base = puptab.pupil_on(puptab.state == "Baseline");
stim = puptab.pupil_on(puptab.state == "Stimulation");
ntr  = [numel(base), numel(stim)];
bf = [sum(base < 0);sum(stim < 0)]./ntr';
sm = [sum(base == 0);sum(stim == 0)]./ntr';
af = [sum(base > 0);sum(stim > 0)]./ntr';

ff = figure;
layout = tiledlayout(2,2);
ax1 = nexttile();
boxchart(puptab.state,puptab.pupil_on)
title("Pupil onset")

ax2 = nexttile();
histogram(pup_on{1},'BinWidth',0.25)
title("Distribution pupil onset during Baseline")

ax3 = nexttile();
bar([bf,sm,af])
title("Rate Pupil onset to locomotion onset")
xticklabels(exp_state)
legend(["before","during","after"])

ax4 = nexttile();
histogram(pup_on{2},'BinWidth',0.25,'FaceColor','r')
title("Distribution pupil onset during Stimulation")

if do_save
    path = '/Volumes/GlyR/GlyR project/Plots/Events_pupil_onset';
    folderpath = fullfile(path,virus,drug);
    n_ev = "/Pupil_locomotion_onset";
    f = fullfile(folderpath,n_ev);
    begonia.path.make_dirs(f)
    print(ff,f,'-r300',"-dpng")
    delete(ff)
    writetable(puptab,f,'FileType','spreadsheet')
end
end