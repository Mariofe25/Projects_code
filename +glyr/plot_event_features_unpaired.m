function plot_event_features_unpaired(mtab,roi_type,state, do_save,out_path)
% make a summary plot with the activity in all fovs and behaviour
% states. Include total time and number of rois
if nargin < 2,roi_type = "neurons"; end
if nargin < 3, state = "Run"; end
if nargin < 4, do_save = false; end

% Get tab segments
tab = mtab(mtab.seg_category == state,:);

% Get only neurons (default)/astrocytes
if roi_type == "neurons"
    tab = tab(startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "ND",:) = [];
else
    tab = tab(~startsWith(tab.roi_type,"N"),:);
    tab(tab.roi_type == "Gp",:) = [];
end

if isempty(tab), fig = []; return, end

% Remove rois w/o events
tab(cellfun(@isempty,tab.events),:) = [];

% Remove post_stimulation state from the multitable
tab(tab.exp_state == "Post-Stimulation",:) = [];

if isempty(tab)
    disp("No " + roi_type + " RoIs found w/ events in" + " the " + ...
        state + "  state of baseline/stimulation")
    return
end

tab(tab.category == "spikes_prob",:) = [];

% Get total number of rois w/ events of each type
rois_t = unique(tab.roi_type);
n_id = unique(tab.roi_short_name);
rois_total = zeros(1,numel(rois_t));
for r = 1:length(rois_t)
    rt = rois_t(r);
    if rt == "NS", rt = "NS "; end
    rois_total(r) = sum(contains(n_id,rt));
end
r_total = containers.Map(rois_t,rois_total);
fs = 30;
% Event features
exp_state = unique(tab.exp_state);
for i = 1: length(exp_state)
    t = tab(tab.exp_state == exp_state(i),:);
    events = [t.events{:}];
    auc = [events.auc]';
    width_half = [events.width_half]'/fs;
    width = [events.width]';
    prom = [events.prominance]';
    amp = [events.y]';
    
    l_ev = cellfun(@length,t.events);
    type = [t.roi_type];
    
    types = arrayfun(@(a,s) repmat(a,s,1),type,l_ev,'UniformOutput',false);
    types = vertcat(types{:});

    roi_id = arrayfun(@(s,g) repmat(s,g,1),t.roi_short_name,l_ev,...
        'UniformOutput',false);
    roi_id = vertcat(roi_id{:});
    
    exp = repmat(exp_state(i),length(events),1);
    
    evs_tab{i} = table(exp,types,roi_id,auc,width_half,width,prom,amp);
end

evs_tab = vertcat(evs_tab{:});
  
%% Plots
n_type = unique(evs_tab.types);
for j = 1:numel(n_type)
    fig = figure('Position',[1000 30 996 1307],'Name',...
        "Events features " + state + " " + unique(tab.exp_category));
    layout = tiledlayout(4,2,'TileSpacing','compact');
    title(layout,"Events features " + state + " " + unique(tab.exp_category))
    hold on
    warning off
    
    % Plot events featues for each RoI type (NS,NS-dnt,Np)-(AS,AE,AP)
    r_evs = evs_tab(evs_tab.types == n_type(j),:);
   
    % auc
    nexttile();
    boxplot(r_evs.auc,r_evs.exp)
    title("AUC   " + r_total(n_type(j)) + " " + n_type(j) + " RoIs")
    ylabel("")
    
    % prominenece
    nexttile();
    boxplot(r_evs.prom,r_evs.exp)
    title("Prominence")
    ylabel("∆F/F")
    
    % amplitude
    nexttile();
    boxplot(r_evs.amp,r_evs.exp)
    title("Amplitude")
    ylabel("∆F/F")
    [~,~,expps] = unique(r_evs.exp);
    if height(r_evs) > 10 && sum(expps(expps == 1)) > 5 && sum(expps(expps == 2)) > 5
        amp_b = bootci(10000,@median,r_evs.amp(r_evs.exp == "Baseline"));
        amp_s = bootci(10000,@median,r_evs.amp(r_evs.exp == "Stimulation"));

        nexttile()
        boxplot([amp_b,amp_s])
        xticklabels(exp_state)
        title("Amplitude. 95% CI boots 10000")
        ylabel("∆F/F")
    end

    % width (aka duration)
    nexttile();
    boxplot(r_evs.width_half,r_evs.exp)
    title("Width half")
    ylabel("Time (secs)")
    if  height(r_evs) > 10 && sum(expps(expps == 1)) > 5 && sum(expps(expps == 2)) > 5
        wh_b = bootci(10000,@median,r_evs.width_half(r_evs.exp == "Baseline"));
        wh_s = bootci(10000,@median,r_evs.width_half(r_evs.exp == "Stimulation"));

        nexttile()
        boxplot([wh_b,wh_s])
        xticklabels(exp_state)
        title("Width half. 95% CI boots 10000")
        ylabel("Time (secs)")
    end
    
    if do_save
        if  nargin == 5 && ~isempty(out_path)
            p = out_path;
        else
            p = "/Volumes/GlyR/GlyR project/Plots/Event_features/Unpaired";
            p = sprintf('%s/%s/%s',p,unique(tab.virus),unique(tab.exp_category));
        end
        filename = roi_type + "/plots/events_unpaired_features_" + ...
            state + "_" + n_type(j);
        filename = fullfile(p,filename);
        begonia.path.make_dirs(filename);
        print(fig,filename,'-r300', '-dpng');
        delete(fig)
        
        %also print the tab 
        tabname = replace(filename,'plots', 'tab');
        begonia.path.make_dirs(tabname);
        writetable(r_evs,tabname,'FileType','spreadsheet')
        
    end
end
end