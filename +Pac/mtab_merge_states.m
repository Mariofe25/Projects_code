function mtab_merged = mtab_merge_states(tss,do_filter,secs)
% merge rois rows with the same segment category to get the number of events
% and seconds in that state. Rows must belong to the same roi id and behav.
% state (aka seg_cat)

if nargin < 3, secs = 3; end
if nargin < 2, do_filter = false; end

import begonia.logging.*

% Load segmented multitabs. Concatenate
log(1,"Loading multitabs")
mtab = tss.load_var("multitab_segmented");
if iscell(mtab)
    mtab = vertcat(mtab{:});
end

% Filter segments by length. Remove segments below x secs. Not include
% Still-Whisking or transiton to motion
if do_filter
    log(1,'Filtering traces (%d secs minimum)',secs)
    dt = unique(mtab.trace_dt);
    tr_len = cellfun(@length,mtab.trace);
    rmv_idx = tr_len < secs/dt;
    excptn = mtab.seg_category == "Transition_still_motion" |...
        mtab.seg_category == "Still-Whisking";
    rmv_idx(excptn) = 0;
    mtab(rmv_idx,:) = [];
end

% Get only calcium traces ans spikes traces
log(1,"Grabbing rois")
mtab = mtab(mtab.category == "ca-roi-dff" | mtab.category == "spikes_prob",:);

% Dummy vars
tab_behavs = [];

% backwrite(1,sprintf('Merging segments of %d/%d',f,numel(fovs)))

% By behaviour state (still,run,...)
behavs = unique(mtab.seg_category);
for b = 1:numel(behavs) 
    log(1,'Merging segments: %s segments', behavs(b))
    behav = mtab(mtab.seg_category == behavs(b),:);
    if isempty(behav), continue,end

    % By roi (choose the short name because it is identical among
    % different recordings of the same fov, the ids are not)
    rois = unique(behav.roi_id,'stable');
    tab = [];
    for r = 1:numel(rois)
        roi = behav(behav.roi_id == rois(r),:);

        if unique(roi.roi_type) ~= "NS"
            roi(roi.category == 'spikes_prob',:) = [];
        end

        % Merge ca2+ traces and spikes_prob (only NS)
        cats = unique(roi.category);
        for c = 1:numel(cats)
            roii = roi(roi.category == cats(c),:);

            % merge dff traces and events
            seg_entities = roii.entity;
            entities = unique(roii.entity);
            traces_idxs = arrayfun(@(s,r) s:r,roii.seg_start_f,...
                roii.seg_end_f,'UniformOutput',false);
            traces_idxs = [traces_idxs{:}]';
            trace = vertcat(roii.trace{:});
            events = [roii.events{:}];

            % delete roi info that's not neccesary or can generate
            % merge conflicts
            delt =["seg_start_f","seg_start_abs","seg_end_f","transition_f"];
            roii(:,delt) = [];

            % Take first instance of the roi to get common info and
            % input the merge trace and events
            roii = roii(1,:);
            roii.segs_entities = {seg_entities};
            roii.entity = {entities};
            roii.trace_idxs = {traces_idxs};
            roii.trace = {trace};
            roii.events  = {events};

            % calculate total seconds in that behav. state
            roii.total_sec = length(trace) * roii.trace_dt;
            rroi(c,:) = roii;
        end
        rroi = movevars(rroi,"total_sec","After","trace_dt");
        tab = [tab;rroi];
        rroi = table();
    end
    tab = sortrows(tab,'roi_type');
    tab_behavs = [tab_behavs;tab];
    tab(:,:) =[]; % need clean up to not duplicate in next iteration
end
mtab_merged = tab_behavs;
log(1,"Segment merge done!")
end