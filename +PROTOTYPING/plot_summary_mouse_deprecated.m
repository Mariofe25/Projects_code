function plot_summary_mouse(mtab,roi_type,state, do_save,out_path)
% make a summary plot with the activity in all fovs and behaviour
% states. Include total time and number of rois

if nargin < 2,roi_type = "neurons"; end
if nargin < 3, state = "Run"; end
if nargin < 4, do_save = false; end

% Get tab segments
mice = unique(mtab.mouse);
for m = 1:length(mice)
    % get rows of a specifc mouse
    tab  = mtab(mtab.mouse == mice(m),:);
    
    glyr.plot_summary_unpaired_state(tab,roi_type,state,0)
    glyr.plot_summary_paired_state(tab,roi_type,state,0)
    % take segemts in a specific state
    tab = tab(tab.seg_category == state,:);
    
    % Get only neurons (default)/astrocytes
    if roi_type == "neurons"
        tab = tab(startsWith(tab.roi_type,"N"),:);
        tab(tab.roi_type == "ND",:) = [];
    else
        tab = tab(~startsWith(tab.roi_type,"N"),:);
        tab(tab.roi_type == "Gp",:) = [];
    end
    
    % Get total number of rois of each type
    rois_t = unique(tab.roi_type);
    tab_base = tab(tab.exp_state == "Baseline",:);
    n_b = unique(tab_base.roi_short_name,'stable');
    tab_stim = tab(tab.exp_state == "Stimulation",:);
    n_s = unique(tab_stim.roi_short_name,'stable');
    
    rois_b = zeros(1,3);
    rois_s = zeros(1,3);
    for r = 1:length(rois_t)
        rt = rois_t(r);
        if rt == "NS", rt = "NS "; end
        rois_b (r) = sum(contains(n_b,rt));
        rois_s(r) = sum(contains(n_s,rt));
    end
    r_b = containers.Map(rois_t,rois_b);
    r_s = containers.Map(rois_t,rois_s);
    
    % Get event frequency in secs and mins
    tab = glyr.get_event_freq(tab);
    tab.events_min = tab.events_sec * 60;
    
    % get rid of rois w/o events
    tab_un = tab(tab.events_min ~= 0,:);
    
    % Get rid of the 'Post-stimulation' state
    tab_un(tab_un.exp_state == "Post-Stimulation",:) = [];
    
    paired = ismember(n_s,n_b);
    
    if sum(paired) ~= 0
        paired_rois = tab_stim.roi_short_name(paired);
        idx = ismember(tab.roi_short_name,paired_rois);
        paired_tab = tab(idx,:);
        paired_tab(paired_tab.exp_state == "Post-Stimulation",:) = [];
        
        % Remove rois w/o events
        for i = 1:numel(paired_rois)
            roi = [paired_tab.events{paired_tab.roi_short_name == paired_rois(i)}];
            if isempty(roi)
                paired_tab( paired_tab.roi_short_name == paired_rois(i),:) = [];
            end
        end
    end
    
    
    
    %% Plots for each FoV
    exp_state = ["Baseline","Stimulation"]; %["Baseline","Stimulation","Post-Stimulation"]
    fovs = unique(tab_un.fov,'stable');
    for f = 1:numel(fovs)
        
        tab_fov = tab(tab.fov == fovs(f),:);
        glyr.plot_summary_unpaired_state(tab_fov,roi_type,state,0)
        glyr.plot_summary_paired_state(tab_fov,roi_type,state,0)
        
        n_type = unique(tab_fov.roi_type);
        fig = figure('Position',[520 30 1533 1307],'Name',...
            "Summary " + state + " " + unique(tab.exp_category));
        layout = tiledlayout(1,2,'TileSpacing','compact');
        title(layout,"Summary " + state + " " + unique(tab.exp_category))
        hold on
        warning off
        for j = 1:numel(n_type)
            % Plot events/min for each RoI type (NS,NS-dnt,Np)-(AS,AE,AP)
            nexttile();
            nb = unique(tab_fov.roi_short_name(tab_fov.roi_type == n_type(j) & ...
                tab_fov.exp_state == exp_state(1)));
            nb = numel(nb);
            ns = unique(tab_fov.roi_short_name(tab_fov.roi_type == n_type(j) & ...
                tab_fov.exp_state == exp_state(2)));
            ns = numel(ns);
            tb = r_b(n_type(j));
            ts =  r_s(n_type(j));
            if numel(unique(tab_fov.exp_state)) == 1
                exp_states = unique(tab_fov.exp_state);
            else
                exp_states = exp_state;
            end
            boxplot(tab_fov.events_min(tab_fov.roi_type == n_type(j)),...
                tab_fov.exp_state(tab_fov.roi_type == n_type(j)))
            title(n_type(j) + ...
                " Events rois w/ events in baseline or stimulation", "RoIs: " + ...
                "Baseline: " +  nb + "/" + tb + "  rate: " + round(nb/tb,2) + ...
                "  Stimulation: " + ns + "/" + ts + "  rate: " + round(ns/ts,2) )
            ylabel("Events/min")
            xticklabels(exp_states)
        end
        warning on
        
        % Plot time in each state
        state_secs = unique(tab_fov.total_sec);
        axt = nexttile(4);
        br = bar(categorical(exp_states),state_secs);
        title("Time in each experimental state")
        ylabel("Time (secs)")
        
        
        % If the FoV has paired data, plot it
        if sum(paired) ~= 0 && any(ismember(paired_tab.fov,fovs(f)))
           
            % Take rois from the current fov
            tab_pair = paired_tab(paired_tab.fov == fovs(f),:);
            
            % need to get the number of rois of each type to later
            % calculate the fraction and ratio of active rois
            rois_t = unique(tab_pair.roi_type);
            n_id = unique(tab_pair.roi_short_name);
            rois_total = zeros(1,numel(rois_t));
            for r = 1:length(rois_t)
                rt = rois_t(r);
                if rt == "NS", rt = "NS "; end
                rois_total(r) = sum(contains(n_id,rt));
            end
            r_total = containers.Map(rois_t,rois_total);
            
            
            
            % need to see again, which are the roi types in the table (migth not
            % contain all the types present in the upaired table)
            n_type = unique(tab_pair.roi_type);
            
            for j = 1:numel(n_type)
                % Plot events/min for each RoI type (NS,NS-dnt,Np)-(AS,AE,AP)
                nexttile();
                n = unique(tab_pair.roi_short_name(tab_pair.roi_type == n_type(j)));
                n = numel(n);
                t = r_total(n_type(j));
                boxplot(tab_pair.events_min(tab_pair.roi_type == n_type(j)),...
                    tab_pair.exp_state(tab_pair.roi_type == n_type(j)))
                title(n_type(j) + ...
                    " Events rois w/ events in baseline or stimulation", "RoIs: " + ...
                    n + "/" + t + "  rate: " + round(n/t,2))
                ylabel("Events/min")
                xticklabels(exp_state)
                
                % Plot % activity change of each RoI type
                ax2 = nexttile();
                hold on
                b = tab_pair.events_min(tab_pair.roi_type == n_type(j) & ...
                    tab_pair.exp_state == "Baseline");
                s = tab_pair.events_min(tab_pair.roi_type == n_type(j) & ...
                    tab_pair.exp_state == "Stimulation");
                total = numel(b);
                comp = s > b;
                comp_2 = s == b;
                comp_3 = s < b;
                prct_g = sum(comp)/total;
                prct_e = sum(comp_2)/total;
                prct_l = sum(comp_3)/total;
                bar(ax2,[prct_g,prct_e,prct_l])
                ylabel("% change")
                title(n_type(j) + " Change percentage Baseline - Stimulation")
                xticks(1:3)
                xticklabels(["Increase","No Change", "Decrease"])
            end           
        end
        
        
        
        
        
        
        
        
        
        
        
    end
end

glyr.plot_summary_unpaired_state

end