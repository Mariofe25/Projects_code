function rois = roi_shot(tss)
% Look for rois that were hit (target) or almost hit(close) by the uncaging
% shot
for ts = tss
    % Load roi_table
    disp(ts.name)
    rois = ts.load_var('roi_table');
%     if any(string(rois.Properties.VariableNames) == "roi_uncaging")
%         disp("RoI(s) with shot already found")
%         rois_uncaging = rois(rois.roi_uncaging == "target",:);
%         rois_close = rois(rois.roi_uncaging == "close",:);
%         return
%     end
    
    % load shot info
    shot = ts.load_var('uncaging_info');
    
    % roi mask indices
    [y_s,x_s] =  cellfun(@find,rois.mask,'UniformOutput',false);
    
    % create vars columns for classification and distance to the shot
    rois.shot_xy_distance = cell(height(rois),1);
    min_x = cellfun(@(s) min(abs(s-shot.x)),x_s,'UniformOutput',false);
    ix = cellfun(@isempty,min_x);
    min_x(ix) = {nan};
    min_y = cellfun(@(s) min(abs(s-shot.y)),y_s,'UniformOutput',false);
    iy = cellfun(@isempty,min_y);
    min_y(iy) = {nan};
    
    % distance rois-shot
    min_dist = arrayfun(@(a,b) [a{:},b{:}],min_x,min_y,'UniformOutput',false);
    rois.shot_xy_distance = min_dist;
    shot_distance = cellfun(@(x) sqrt(sum(x.^2)),min_dist);
    rois.shot_distance = shot_distance;
    
    % Categorize rois by uncaging distance
    range = 10:10:100;
    rois.uncaging_category = repmat(categorical(""),height(rois),1);
    rsd = rois.shot_distance;
    rois.uncaging_category(rsd < 1) = "target";
    rois.uncaging_category(rsd > 1 & rsd < 10) = "close";
    
    for r = 1:length(range)
        if r < 10
            rois.uncaging_category(rsd > range(r) & rsd < range(r + 1)) = ...
                range(r)+ "-" + range(r + 1);
        else
            rois.uncaging_category(rsd > range(r)) = ">" + range(r);
        end
    end
    
    if ~any( rois.uncaging_category == "target")
        disp("No RoI(s) with shot found in " + ts.name)
    else
        disp(sum(rois.uncaging_category == "target") + " RoI(s) colocalize w/ the uncaging shot")
    end
    disp(sum(rois.uncaging_category == "close") + " RoI(s) close to the shot spot (<10px)")    
    rois = rois(:,[1:4,7,end-3:end]);    
    ts.save_var('rois_target',rois)
end
end