function plot_align2locomotion_by(tss,level,do_tabs,do_plots,do_heatmaps)
if nargin < 5, do_heatmaps = true; end
if nargin < 4, do_plots = true; end
if nargin < 3, do_tabs = true; end
if nargin < 2, level = "all"; end

if ~any(strcmp(level,["all","fov","mouse"]))
    error("'level'input argument must be one of these three: 'all','mouse' or 'fov'")
end

% load one random tseries(1) to grab the experimetnal and virus category
virus = unique(string(tss.load_var('virus')));
ts = tss(1);
if contains(ts.path,"post")
    exp_cat = "postIVM";
elseif contains(ts.path,"IVM")
    exp_cat = "IVM";
else
    exp_cat = "noIVM";
end

% Parent directory
save_path = '/Volumes/GlyR/GlyR project/Plots/Modulatory_index/Running';
save_path = fullfile(save_path,virus,exp_cat,'Aligned');

% Procces by fov,mouse or all together
if level == "fov"
    % plot rois, align to locomotion onset by fov
    fovs = tss.load_var("RFOV");
    fovs = string(fovs);
    fovs_un = unique(fovs,'stable');
    save_path = fullfile(save_path,'FoVs');
    for i = 1:length(fovs_un)
        idx = fovs == fovs_un(i);
        tf = tss(idx);
        % merge same rois present in different tseries
        tab = glyr.merge_fov_rois(tf);
        % plot traces aligned to onset (1sec transition and 7sec
        % locomotion(motion/run)
        [baseline,stimulation,types,fig_b,fig_s] = glyr.align_roi_type(tab,[],true);
        fov_path = fullfile(save_path,fovs_un(i));
        if do_heatmaps
            [h_b,h_s] = glyr.plot.heatmap_align2loc(tss,baseline,stimulation,types);
        else
            h_b = [];
            h_s = [];
        end
        save_it(do_tabs,do_plots,do_heatmaps,baseline,stimulation,types,fig_b,fig_s,h_b,h_s,fov_path)
    end
    
elseif level == "mouse"
    mouse = tss.load_var("mouse");
    mouse = string(mouse);
    mouse_un = unique(mouse,'stable');
    save_path = fullfile(save_path,'Mouse');
    for i = 1:length(mouse_un)
        idx = mouse == mouse_un(i);
        tf = tss(idx);
        % merge same rois present in different tseries
        tab = glyr.merge_fov_rois(tf);
        [baseline,stimulation,types,fig_b,fig_s] = glyr.align_roi_type(tab,[],true);
        mouse_path = fullfile(save_path,mouse_un(i));
        if do_heatmaps
            [h_b,h_s] = glyr.plot.heatmap_align2loc(tss,baseline,stimulation,types);
        else
            h_b = [];
            h_s = [];
        end
        save_it(do_tabs,do_plots,do_heatmaps,baseline,stimulation,types,fig_b,fig_s,h_b,h_s,mouse_path)
    end
    
else
    tab = glyr.merge_fov_rois(tss);
    [baseline,stimulation,types,fig_b,fig_s] = glyr.align_roi_type(tab,[],true);
    save_path = fullfile(save_path,'All');
    if do_heatmaps
        [h_b,h_s] = glyr.plot.heatmap_align2loc(tss,baseline,stimulation,types);
    else
        h_b = [];
        h_s = [];
    end
    save_it(do_tabs,do_plots,do_heatmaps,baseline,stimulation,types,fig_b,fig_s,h_b,h_s,save_path)
end
end

function save_it(do_tabs,do_plots,do_heatmaps,baseline,stimulation,types,fig_b,fig_s,h_b,h_s,path)
if do_plots
    base_filename = fullfile(path,'plot','Baseline');
    stim_filename = fullfile(path,'plot','Stimulation');
    begonia.path.make_dirs(base_filename);
    begonia.path.make_dirs(stim_filename);
    print(fig_b,base_filename,'-r300', '-dpng')
    print(fig_s,stim_filename,'-r300', '-dpng')
    delete(fig_b)
    delete(fig_s)
end
if do_tabs
    for i = 1:length(types)
        t = types(i)+".xlsx";
        base_tab_filename = fullfile(path,'tab','Baseline',t);
        stim_tab_filename = fullfile(path,'tab','Stimulation',t);
        begonia.path.make_dirs(base_tab_filename);
        begonia.path.make_dirs(stim_tab_filename);
        idx_b = all(isnan(baseline{i}'));
        base = baseline{i}(~idx_b,:)';
        idx_s = all(isnan(stimulation{i}'));
        stim = stimulation{i}(~idx_s,:)';
        if ~isempty(base)
            writematrix(base,base_tab_filename,'FileType','spreadsheet');
        end
        if ~isempty(stim)
            writematrix(stim,stim_tab_filename,'FileType','spreadsheet');
        end
    end
end
if do_heatmaps
    for i = 1:length(types)
        hb_filename = fullfile(path,'heatmap','Baseline',types(i));
        hs_filename = fullfile(path,'heatmap','Stimulation',types(i));
        begonia.path.make_dirs(hb_filename);
        begonia.path.make_dirs(hs_filename);
        if ~isempty(h_b{i})
            print(h_b{i},hb_filename,'-r300', '-dpng');
            delete(h_b{i})
        end
        if ~isempty(h_s{i})
            print(h_s{i},hs_filename,'-r300', '-dpng');            
            delete(h_s{i})
        end     
    end
end
end