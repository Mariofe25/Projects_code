function move2multitab(tss,trials,fs)
import begonia.data_management.multitable.*
import begonia.logging.*

if nargin < 3, fs = 10; end

warning("If multitab was created and events were already detected, running " + ...
    "this will overwritte multitab, deleteting detected events. Remember to " + ...
    "find events again")

% create multitable
disp("Creating multitable...")
mtab = MultiTable();
entities = replace(string({tss.name}), "TSeries", "Experiment");

% add data
disp("Adding data...")

% behaviour
add_dloc_vector(mtab, entities, "drift", tss, "drift_correction_trace", [tss.dt]);
% add_dloc_timeseries(mtab, entities, "wheel", trials, "wheel_trim");
add_dloc_timeseries(mtab, entities, "speed", trials, "speed");
add_dloc_timeseries(mtab, entities, "whisker", trials, "whisking_trim");

% rois
add_ca_roi(mtab, entities, "ca-roi-dff", tss, "roi_signals_dff");
add_ca_roi(mtab, entities, "ns-roi-dff", tss, "roi_signals_dff_subtracted");
add_ca_roi(mtab, entities, "spikes_prob", tss, "spike_prob");

% behaviour trace to segment multitab
add_dloc_vector(mtab, entities, "locomotion", trials, "locomotion", 1/20);
add_dloc_timeseries(mtab, entities, "whisking", trials, "whisking");


% msg = fprintf('Getting/Sync traces by entity: 0 of %d', length(entities));
for i = 1:numel(entities)
    try
        msg = sprintf('Getting/Sync traces by entity: %d of %d\n', i, length(entities));
        backwrite(1,msg)
        % Get multitab traces
        traces = mtab.by_entity(entities(i));

        % Force-add neurons donuts (has to be this way because data is not in
        % roi_table)
        traces = add2mtab_ns_dnt(tss(i),traces,"ca-roi-dff","donut_dff");
        
        % change NS for NS subtracted;
        old_signals = traces.category == "ca-roi-dff" & traces.roi_type == "NS";
        new_signals = traces.category == "ns-roi-dff" & traces.roi_type == "NS";
        traces.trace(old_signals) = traces.trace(new_signals);

        % Remove "ns-roi-dff" category
        traces(traces.category == "ns-roi-dff",:) = [];

        % Resample and make the same length
        traces_sync = equisize_left(traces,"trim",1/fs);
        multitab = sortrows(traces_sync,{'category','roi_type'});

        % Add mouse name 
        mouse = string(tss(i).load_var('mouse'));
        multitab.mouse(:) = mouse;

        % Add genotype
        gen = tss(i).load_var('genotype');
        multitab.genotype(:) = gen; 

        % Save in tseries metadata
        tss(i).save_var('multitab',multitab)
    catch err
        warning("Err.idx: " + i + "/" + length(entities) + ". " + string(err.message) +'\n')
    end
end
disp("Done!")
end

function traces = add2mtab_ns_dnt(tss,traces,category,var)
tab = tss.load_var(var);
rows_category = traces(traces.category == category,:);
ns_dnt = tab(tab.type == "NS-dnt",:);
add = repmat(rows_category(end,:),height(ns_dnt),1);
add.roi_type = ns_dnt.type;
add.roi_id = ns_dnt.roi_id;
add.roi_short_name = ns_dnt.short_name;
add.channel(:) = 2;
try
    signals = cellfun(@transpose,ns_dnt.signal_events,'UniformOutput',false);
    add.trace = signals;
catch
    signals = cellfun(@transpose,ns_dnt.signal_donut_dff,'UniformOutput',false);
    add.trace = signals;
end
traces = [traces;add];
end