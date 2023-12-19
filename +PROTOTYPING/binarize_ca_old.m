function ca_binarized = binarize_ca(tss)
for ts = tss
    % Get signals
    rois = begonia.processing.roi.load_processed_signals(ts);
    ns_dnt = ts.load_var('donut_dff');
    
    % Remove signal from shot
    [rois,ns_dnt] = Pac.remove_shot_signal(ts,rois,ns_dnt);
    
    % Separate astrocytes & neurons
    var_names = {'roi_id', 'signal'};
    ast_rois = rois(rois.channel == 1,{'roi_id','signal_dff'});
    ast_rois.Properties.VariableNames = var_names;
    ns_rois = rois(rois.type == "NS",{'roi_id','signal_subtracted_dff'});
    ns_rois.Properties.VariableNames = var_names;
    np_rois = rois(rois.type == "Np",{'roi_id','signal_dff'});
    np_rois.Properties.VariableNames = var_names;
    ns_dnt = ns_dnt(:,{'roi_id','signal_donut_dff'});
    ns_dnt.Properties.VariableNames = var_names;
    neu_rois = [ns_rois;ns_dnt;np_rois];
    astrocytes_binarized = binarize_astrocytes(ast_rois);
    neurons_binarized = binarize_neurons(neu_rois);
    ca_binarized = [astrocytes_binarized;neurons_binarized];
    ts.save_var('Ca_events',ca_binarized)
end
end

function  astrocytes_binarized = binarize_astrocytes(rois)
rois_trace = rois.signal;
rois_trace = cellfun(@(r) r + abs(min(r)),rois_trace,'UniformOutput',false);
% Smooth trace (sgolay filter, 1st order, window size)
roi_filt = cellfun(@(s) sgolayfilt(s,1,31),rois_trace,'UniformOutput',false);
% Noise = df/f0 - low_pass filtered df/f0 (aka highpass filter)
noise = cellfun(@minus,rois_trace,roi_filt,'UniformOutput',false);
noise = cellfun(@abs,noise,'UniformOutput',false);
noise = cellfun(@(s) prctile(s,50),noise);
threshold = 3*noise;
% Rule 1. is event if signal is higher than 3 times the noise signal
ca_events  = arrayfun(@(s,d) s{:} > d,roi_filt,threshold,'UniformOutput',false);
% Rule 2. Is event if it is at least 0.3
%r2 = roi_trace >= 0.3;
roi_id = rois.roi_id;
astrocytes_binarized = table(roi_id,ca_events,'VariableNames',{'roi_id','signal_events'});
end

function neurons_binarized = binarize_neurons(rois)
f = rois.signal_raw;
f = cellfun(@(s) s',f,'UniformOutput',false);
ss = cellfun(@(s) movstd(s,300),f,'UniformOutput',false);
[~,m] = cellfun(@min,ss);
f0 = arrayfun(@(s,g) s{:}(g),f,m,'UniformOutput',false);
f0 = [f0{:}]';
df_f = arrayfun(@(s,d) (s{:} - d)/d,f,f0,'UniformOutput', false);   %calculate delta f
% nois = cellfun(@(s) median(s(s < 0)),df_f1,'UniformOutput',false);
% df_f= arrayfun(@(s,d) s{:} - d{:},df_f1,nois,'UniformOutput',false);
df_f = cellfun(@(s) sgolayfilt(s,1,31),df_f,'UniformOutput',false);
stdev = cellfun(@(s) min(movstd(s,300)),df_f,'UniformOutput',false);
stdev2 = 2*[stdev{:}];

ca_events = arrayfun(@(s,f) s{:,1} > f,df_f,stdev2','UniformOutput',false);
ca_events = cellfun(@(s) s',ca_events,'UniformOutput',false);
roi_id = rois.roi_id;
neurons_binarized = table(roi_id,ca_events,'VariableNames',{'roi_id','signal_events'});
end