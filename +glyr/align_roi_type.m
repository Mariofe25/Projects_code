function [baseline,stimulation,types,fig_b,fig_s] = align_roi_type(roi_tab,types,do_figure)
if nargin < 3, do_figure = false; end
if isempty(types) || nargin < 2
    types = unique(roi_tab.roi_type);
end
types(types == "ND") = [];
types(types == "Gp") = [];
glyr.plot.roi_type_colors;
for i = 1:length(types)
    rois = roi_tab(roi_tab.roi_type == types(i),:);
    % to make it easier, eliminate pre transition with more than 30 frames
    % (some of them have 31)
    idx_b = find(cellfun(@length,rois.base_before) > 30);
    idx_s = find(cellfun(@length,rois.stim_before) > 30);
    
    for b = 1:numel(idx_b)
        rois.base_before{idx_b(b)}(1) = [];
    end
    
    for s = 1:numel(idx_s)
        rois.stim_before{idx_s(s)}(1) = [];
    end
    
    base_before = horzcat(rois.base_before{:});
    base_after = horzcat(rois.base_after{:});
    baseline{i} = [base_before;base_after]';
    %     baseline = sgolayfilt(baseline,1,11,[],2);
    n_rois_b(i) = sum(any(~isnan(baseline{i}')));
    
    stim_before = horzcat(rois.stim_before{:});
    stim_after = horzcat(rois.stim_after{:});
    stimulation{i} = [stim_before;stim_after]';
    n_rois_s(i) = sum(any(~isnan(stimulation{i}')));
    %     stimulation = sgolayfilt(stimulation,1,11,[],2);
end


% Plot average ± sem  by roi type and experimental state
% (baseline/Stimulation)
if do_figure
    fig_b = figure;
    fig_s = figure;
    layout_b = tiledlayout(fig_b,3,2,"tilespacing", "compact");
    layout_s = tiledlayout(fig_s,3,2,"tilespacing", "compact");
    for t = 1:length(types)
        nexttile(layout_b)
        glyr.stdshade(baseline{t},0.3,roi_colors(types(t)),[],11);
        hold on
        xline(30,'LineWidth',2,'LineStyle','--')
        title(types(t) + ": " + n_rois_b(t))
        if startsWith(types(t),"A")
            ylim([0,0.3])
        else
            ylim([0,0.12])
        end
        hold off
        
        nexttile(layout_s)
        glyr.stdshade(stimulation{t},0.3,roi_colors(types(t)),[],11);
        hold on
        xline(30,'LineWidth',2,'LineStyle','--')
        title(types(t) + ": " + n_rois_s(t))
        if startsWith(types(t),"A")
            ylim([0,0.3])
        else
            ylim([0,0.12])
        end
        hold off
    end
    
    title(layout_b,'Baseline, rois alingn to locomotion onset')
    xlabel(layout_b,'frames')
    ylabel(layout_b,'∆F/F')
    
    title(layout_s,'Stimulation, rois alingn to locomotion onset')
    xlabel(layout_s,'frames')
    ylabel(layout_s,'∆F/F')
end
end