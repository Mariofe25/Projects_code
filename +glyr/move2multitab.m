function multitab = move2multitab(tss,trials,fs)
% Move RoIs & rig traces to a table to ease posterior analysis
import begonia.data_management.multitable.*
import begonia.logging.*;
if nargin < 3, fs = 30; end

% verbose
set_level(1)

% create multitable
log(1,"Creating multitable...")
mtab = MultiTable();
entities = replace(string({tss.name}), "TSeries", "Experiment");

% add data
log(1,"Adding data...")
add_dloc_vector(mtab, entities, "drift", tss, "drift_correction_trace", [tss.dt]);
add_dloc_timeseries(mtab, entities, "wheel", trials, "wheel_trim");
add_dloc_timeseries(mtab, entities, "speed", trials, "speed");
add_dloc_timeseries(mtab, entities, "whisker", trials, "whisking_trim");
%not all trials have pupil data
t_idx = trials.has_var('pupil-rate_trim');
add_dloc_timeseries(mtab, entities(t_idx), "pupil", trials(t_idx), "pupil_trim");
add_dloc_timeseries(mtab, entities(t_idx), "pupil_ratio", trials(t_idx), "pupil-rate_trim");
add_ca_roi(mtab, entities, "ca-roi-dff", tss, "roi_signals_dff");
add_ca_roi(mtab, entities, "ns-roi-dff", tss, "roi_signals_dff_subtracted");
% try
%     add_ca_roi(mtab, entities, "spikes_prob", tss, "Spike_prob");
% catch
%     warning("No Spike probablity found")
% end

% trace to later segment data
add_dloc_vector(mtab,entities,"exp_state",trials,"trace_cat",1/30)
add_dloc_vector(mtab, entities, "locomotion", trials, "locomotion", 1/20);

% Binarized data
%add_dloc_timeseries(mtab, entities, "running", trials, "running");
add_dloc_timeseries(mtab, entities, "whisking", trials, "whisking");

try
    % add_ca_roi(mtab, entities, "ca_events", tss, "ca_events");
catch
    warning("no binarize calcium signals found")
end

% msg = fprintf('Getting/Sync traces by entity: 0 of %d', length(entities));
for i = 1:numel(entities)
    try
        %         fprintf(repmat('\b',1,msg))
        msg = sprintf('Getting/Sync traces by entity: %d of %d\n', i, length(entities));
        backwrite(1,msg)
        % disp(i + "/" + length(entities) + " Getting/Sync traces of each experiment")
        
        % Get multitab traces
        traces = mtab.by_entity(entities(i));
        
        % Force-add neurons donuts (has to be this way because data is not in
        % roi_table)
        traces = add2mtab_ns_dnt(tss(i),traces,"ca-roi-dff","donut_dff");
        %     traces = add2mtab_ns_dnt(tss(i),traces,"ca_events","ca_events");
        
        % change NS for NS subtracted;
        old_signals = traces.category == "ca-roi-dff" & traces.roi_type == "NS";
        new_signals = traces.category == "ns-roi-dff" & traces.roi_type == "NS";
        traces.trace(old_signals) = traces.trace(new_signals);
        
        % Remove "ns-roi-dff" category
        traces(traces.category == "ns-roi-dff",:) = [];
        
        % Resample and make the same length
        %traces_30fps = resample(traces,1/fs);
        traces_sync = equisize_left(traces,"trim",1/fs);
       
        % sort rows by roi type
        multitab = sortrows(traces_sync,{'category','roi_type'});      
                
        % add traces indices (1:lenght(traces))
%         l = unique(cellfun(@length,multitab.trace));
%         multitab.trace_idxs(:) = {1:l};
%         multitab.trace_idxs = cellfun(@transpose,multitab.trace_idxs,'UniformOutput',false);
%         multitab = movevars(multitab,'trace_idxs','After','trace');
              
        % Add mouse name and FoV to mtab
        ts_path = string(tss(i).path);
        mouse = regexp(ts_path,"\<[A-Z]{2}\>","match"); % Mice are named w/ 2 upper case letters
        fov = tss(i).load_var("RFOV");
        
        multitab.mouse(:) = mouse;
        multitab.fov(:) = string(fov);
        
        % Save in tseries metadata
        tss(i).save_var('multitab',multitab)
    catch err
        warning("Err.idx: " + i + "/" + length(entities) + ". " + string(err.message) +'\n')
        %         disp(repmat('',1,msg))
    end
end
log(1,"Done!")
% Segment data (locomotion)
% import begonia.data_management.multitable.segment_globally;
% sequence = Pac.categorize_loc(trials(1));
% s = categories(sequence);
% fps = 20;
% segs = segment_globally(traces_1, traces_1.trace{2}, 1/10,s);
end

function traces = add2mtab_ns_dnt(tss,traces,category,var)
tab = tss.load_var(var);
rows_category = traces(traces.category == category,:);
ns_dnt = tab(tab.type == "NS-dnt",:);
add = repmat(rows_category(end,:),height(ns_dnt),1);
add.roi_type = ns_dnt.type;
add.roi_id = ns_dnt.roi_id;
add.roi_short_name = ns_dnt.short_name;
try
    signals = cellfun(@transpose,ns_dnt.signal_events,'UniformOutput',false);
    add.trace = signals;
catch
    signals = cellfun(@transpose,ns_dnt.signal_donut_dff,'UniformOutput',false);
    add.trace = signals;
end
traces = [traces;add];
end