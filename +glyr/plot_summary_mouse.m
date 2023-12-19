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
    mouse = mice(m);
    virus = unique(tab.virus);
    exp_cat = unique(tab.exp_category);
    tab(tab.exp_state == "Post-Stimulation",:) = [];
    
    % Plot  unpaired
    if ~any(ismember(state,tab.seg_category))
        continue
    end
    fig = glyr.plot_summary_unpaired_state(tab,roi_type,state,0);
    if do_save  && ~isempty(fig)
        save_it(fig,"Unpaired",mouse,[],virus,exp_cat,state,roi_type)
    end
    
    % Plot paired
    if numel(unique(tab.exp_state(tab.seg_category == state))) == 2
        fig =  glyr.plot_summary_paired_state(tab,roi_type,state,0);
        if do_save  && ~isempty(fig)
            save_it(fig,"Paired",mouse,[],virus,exp_cat,state,roi_type)
        end
    end
    
    
    %% Plots for each FoV
    fovs = unique(tab.fov,'stable');
    for f = 1:numel(fovs)
        tab_fov = tab(tab.fov == fovs(f),:);
        tab_fov = tab_fov(tab_fov.seg_category == state,:);
        tab_fov(tab_fov.exp_state == "Post-Stimulation",:) = [];
        
        % If fov has paired rois, plot only the paired
        if ~isempty(tab_fov)
            if numel(unique(tab_fov.exp_state)) ~= 2
                fig = glyr.plot_summary_unpaired_state(tab_fov,roi_type,state,0);
                if do_save && ~isempty(fig)
                    save_it(fig,"Unpaired",mouse,fovs(f),virus,exp_cat,state,roi_type)
                end
            else
                fig =  glyr.plot_summary_paired_state(tab_fov,roi_type,state,0);
                if do_save && ~isempty(fig)
                    save_it(fig,"Paired",mouse,fovs(f),virus,exp_cat,state,roi_type)
                end
            end
        end
    end
end
end

function save_it(fig,mode,mouse,fov,virus,exp_cat,state,roi_type)
% mode: paired or unpaired
if isempty(fov)
    p = "/Volumes/GlyR/GlyR project/Plots/Activity_summary/By_mouse/"...
        + mouse;
else
    p = "/Volumes/GlyR/GlyR project/Plots/Activity_summary/By_mouse/"...
        + mouse + "/By_FoV/" + fov;
end
p = sprintf('%s/%s/%s',p,virus,exp_cat);
filename = roi_type + "/events_" + mode + "_summary_" + ...
    state + "_" + exp_cat;
filename = fullfile(p,filename);
begonia.path.make_dirs(filename);
print(fig,filename,'-r300', '-dpng');
delete(fig)
end