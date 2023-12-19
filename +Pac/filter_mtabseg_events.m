function mtab = filter_mtabseg_events(tss)
% Filter events in segmented multitab. It removes events that are not
% within the segment length
import begonia.logging.*;
for ts = tss
    log(1,"Filtering events of " + ts.name)
    mtab = ts.load_var("multitab_segmented");

    % % important to sort the mtab before to assign the correct events
    % mtab = sortrows(mtab,{'roi_id','seg_start_f'},'ascend');

    % Get rois
    m = sum(mtab.category == 'ca-roi-dff');
    for i = 1:m
        if mtab.category(i) ~= "ca-roi-dff",continue, end
        backwrite(1,'Filtering segments:%d/%d',i,m)
        events = mtab.events{i};
        if ~isempty(events)
            % Get start & end frames of segment
            % Find if start of the events are whithin the segment
            % Sometimes it happens that the segments are short and/or are
            % interrupted by another segment. In that case the evetns are
            % not assigned to any segemnt. Workaround: assign the event to
            % the segment where it starts if it is greater than the start
            % frame of the segment
            st =  mtab.seg_start_f(i);
            sp = mtab.seg_end_f(i);
            if i < m
                st1 = mtab.seg_start_f(i+1);
                sp1 = mtab.seg_end_f(i+1);
                if st < st1
                    s = ([events.x_start_idx] >= st  &  [events.x_start_idx] < st1) ...
                        & ([events.x_start_idx] < sp | [events.x_start_idx] < sp1);
                else
                    s = [events.x_start_idx] >= st  & [events.x_start_idx] < sp ;
                end
            else
                s = [events.x_start_idx] >= st  & [events.x_start_idx] < sp ;
            end

            % Remove selected events from mtab segments
            events(~s) = [];
            mtab.events{i} = events;

            % If no remaining events in the struct, remove it
            if isempty(events)
                mtab.events{i} = [];
            end
        else
            continue
        end
    end

    % Update segmented multitab
    ts.save_var("multitab_segmented",mtab)
end
log(1,"Segment Events Filtered!")