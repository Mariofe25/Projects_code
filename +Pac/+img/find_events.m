function mtab = find_events(tss)

% Find events of astrocytes and neurons
% Parameteres includes some fixed values to filter detected events
import begonia.logging.*;
ast_window = 60;
neu_window = 30;
ast_gtx = 2.5;
neu_gtx = 3;

begonia.logging.set_level(2)

for ts = tss
    mtab = ts.load_var("multitab");
    log(1,"Finding events in " + ts.name)

    fs = round(1/unique(mtab.trace_dt));

    % event parameters for astrocytes and neurons
    param = glyr.default_parameters;

    % grab traces
    ca = mtab(mtab.category == "ca-roi-dff",:);

    % find events for astroyctes
    astrocytes = ca(ca.channel == 1,:);
    ast_evs = Pac.img.peak_finder(astrocytes,param,fs,ast_window,ast_gtx);

    % find events for neurons
    backwrite()
    neurons = ca(ca.channel == 2,:);
    neu_evs = Pac.img.peak_finder(neurons,param,fs,neu_window,neu_gtx);

    % add evnets to mtab
    mtab.events = cell(height(mtab),1);
    events = [ast_evs;neu_evs];
    mtab.events(1:length(events)) = events;

    ts.save_var("multitab",mtab)
end
begonia.logging.set_level(1)
end