function [rois,ns_dnt] = remove_shot_signal(ts,rois,ns_dnt)
if ts.has_var('uncaging_info')
    uncage = ts.load_var('uncaging_info');
    un_start = uncage.Start;
    un_end = uncage.End;
    uncaging = un_start:un_end;
    % ast & np
    traces = rois.signal_dff;
    traces_dff = remove_it(traces,uncaging);
    rois.signal_dff = traces_dff;
    % ns
    traces = rois.signal_subtracted_dff;
    traces_dff = remove_it(traces,uncaging);
    rois.signal_subtracted_dff = traces_dff;
    % ns_dnt
    traces = ns_dnt.signal_donut_dff;
    traces_dff = remove_it(traces,uncaging);
    ns_dnt.signal_donut_dff =  traces_dff;
end
end

function traces_dff = remove_it(traces,uncaging)
traces_dff = cell2mat(traces)';
traces_dff(uncaging,:)= hampel(traces_dff(uncaging,:));
traces_dff = traces_dff';
traces_dff = num2cell(traces_dff,2);
end