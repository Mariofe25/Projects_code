function mtab = find_rois_events(tss)
% Find events of astrocytes and neurons. It only finds positive peak
% Parameteres can be changed
import begonia.logging.*;

for ts = tss
    mtab = ts.load_var("multitab");
    rois = begonia.processing.roi.load_processed_signals(ts);
    rois(rois.type == "ND",:) = [];
    donut = ts.load_var("donut_dff");
    donut.Properties.VariableNames(end-1) = {'signal_dff'};
    rois = rois(:,donut.Properties.VariableNames);
    rois =  [rois;donut];
    rois = sortrows(rois,"type");
    log(1,"Finding events in " + ts.name)
    
    % event parameters for astrocytes and neurons
    param = glyr.default_parameters;
    
    % grab traces
    traces = cat(1,rois.signal_dff{:})';
    traces(isnan(traces)) = 0;
    
    % get first neuron roi (mtab is already sorted, so astrocytes rois will
    % be positioned first always)
    neu_idx = find(startsWith(rois.type,"N"),1,"first");
    
    % find events for astroyctes
    ast_ev = cell(neu_idx-1,1);
    ast_traces = traces(:,1:neu_idx-1);
    for i = 1:size(ast_traces,2)
        msg = sprintf('Astrocyte RoIs: %d/%d',i,size(ast_traces,2));
        backwrite(1,msg)
        ev =  glyr.find_events_ast(ast_traces(:,i),30,param,1);
        if ~isempty(ev)
            ev([ev.x] < 5) = [];
            if isempty(ev), ev = []; end
        end
        ast_ev{i} = ev;
    end
    
    % find events for neurons
    backwrite()
    neu_ev = cell(size(traces,2) - neu_idx + 1,1);
    neu_traces = traces(:,neu_idx:size(traces,2));
    for i = 1:size(neu_traces,2)
        backwrite(1,'Neuron RoIs: %d/%d',i,size(neu_traces,2))
        ev = glyr.find_events_neu(neu_traces(:,i),30,param,1);
        if ~isempty(ev)
            ev([ev.x] < 5) = [];
            if isempty(ev), ev = []; end
        end
        neu_ev{i} = ev;
    end
    
    % add evnets to mtab
    mtab.events = cell(height(mtab),1);
    events = [ast_ev;neu_ev];
    mtab.events(1:size(traces,2)) = events;
    
    ts.save_var("events")
    ts.save_var("multitab",mtab)
end
end