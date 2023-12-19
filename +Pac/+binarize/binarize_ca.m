function ca_binarized = binarize_ca(tss,fs)
if nargin < 2, fs = 10; end
for ts = tss
    % Get signals
    disp("Binarizing " + ts.name)
    rois = begonia.processing.roi.load_processed_signals(ts);
    ns_dnt = ts.load_var('donut_dff');
    
    % Remove signal from shot
    [rois,ns_dnt] = Pac.remove_shot_signal(ts,rois,ns_dnt);
    
    % Separate astrocytes & neurons
    var_names = {'id','roi_id', 'signal','type'};
    ast_rois = rois(rois.channel == 1,{'short_name','roi_id','signal_dff','type'});
    ast_rois.Properties.VariableNames = var_names;
    ast_rois = sortrows(ast_rois,'type');
    ns_rois = rois(rois.type == "NS",{'short_name','roi_id','signal_subtracted_dff','type'});
%     ns_rois.type = repmat("NS",height(ns_rois),1);
    ns_rois.Properties.VariableNames = var_names;
    np_rois = rois(rois.type == "Np",{'short_name','roi_id','signal_dff','type'});
    np_rois.Properties.VariableNames = var_names;
    ns_dnt = ns_dnt(:,{'short_name','roi_id','signal_donut_dff'});
    ns_dnt.type = repmat("NS-dnt",height(ns_dnt),1);
    ns_dnt.Properties.VariableNames = var_names;
    neu_rois = [ns_rois;ns_dnt;np_rois];
    
    % Parameters
    parameters = Pac.binarize.default_parameters();
    
    % Peaks astrocytes & neurons
    ast_traces = cat(1,ast_rois.signal{:})';
    ast_peaks = Pac.binarize.find_events_ast(ast_traces,fs,parameters);
    neu_traces = cat(1,neu_rois.signal{:})';
    neu_peaks = Pac.binarize.find_events_neu(neu_traces,fs,parameters);
    
    % Binarize Signals
    astrocytes_binarized = binarize_it(ast_rois,ast_peaks);  
    neurons_binarized = binarize_it(neu_rois,neu_peaks);
    ca_binarized = [astrocytes_binarized;neurons_binarized];
    ts.save_var('ca_events',ca_binarized)
end
end

function  binarized_tab = binarize_it(rois,peaks)
binarized_signal = cell(height(rois),1);
for i = 1:height(rois)
    trace = rois.signal{i};
    ca_events = zeros(1,length(trace));
    if isempty(peaks)
        binarized_signal{i} = ca_events;
        continue
    end
    idx = [peaks.trace_idx]';
    n_peaks = find(idx == i);
    start = [peaks(n_peaks).x_start_idx];
    stop = [peaks(n_peaks).x_end_idx];
    ca_events = zeros(1,length(trace));
    
    for j = 1:numel(n_peaks)
        ca_events(start(j):stop(j)) = 1;
    end
    binarized_signal{i} = ca_events;
end
binarized_signal = cellfun(@logical,binarized_signal,'UniformOutput',false);
rois_id = rois.roi_id;
type = rois.type;
id = rois.id;
binarized_tab = table(id,rois_id,binarized_signal,type,'VariableNames',{'id','roi_id','signal_events','type'});
end