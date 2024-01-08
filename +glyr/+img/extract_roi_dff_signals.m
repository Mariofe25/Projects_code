function extract_roi_dff_signals(tss,do_nuclei)

if nargin < 2, do_nuclei = false; end

import begonia.logging.log;
n = 0;
for ts = tss
    % we need to have the roi signals to perform this processing:
    if ~ts.has_var("roi_signals_raw")
        begonia.processing.roi.extract_roi_signals(ts);
    end
    dt = ts.dt;
    n = n + 1;


    roi_signal_raw = ts.load_var("roi_signals_raw");
    roi_table = ts.load_var("roi_table");

    roi_signal_raw = join(roi_signal_raw, roi_table);
    signal = vertcat(roi_signal_raw.signal_raw{:});

    % Astrocytes
    ast_idx = roi_signal_raw.channel == 1;
    if  any(ast_idx)
        log(1, "Extracting astrocytes df_f0 roi signals: " + ts.name);
        ast = signal(ast_idx,:);
        [ast_dff,ast_f0] = glyr.img.get_dff_roi(ast,"astrocyte",dt);
        ast_dff = num2cell(ast_dff', 2);
    else
        ast_dff = [];
        ast_f0 = [];
    end

    % Neurons
    ns_idx =  roi_signal_raw.type == "NS";
    if any(ns_idx)
        log(1, "Extracting neurons df_f0 roi signals: " + ts.name);
        if do_nuclei
            log(1, "Removing ROIs' nuclei pixels to increae SNR")
            ns = glyr.mask_neurons(ts);
        else
            ns = signal(ns_idx,:);
        end
        log(1, "Getting donut signal for neuropil subtraction")
        donut = ts.load_var("roi_signals_doughnut");
        donut = donut.signal_doughnut(ns_idx);
        donut = vertcat(donut{:});
        [ns_dff,ns_f0] =  glyr.img.get_dff_roi(ns,"neuron",dt,1,0.7,donut);
        ns_dff = num2cell(ns_dff', 2);

        % Dff donut signal (done this way to not change all teh other
        % scrits and functions, but it would be better if extracted like
        % the other roi types
        [dnt_dff,dnt_f0] =  glyr.img.get_dff_roi(donut,"neuron",dt,0);
        signal_donut_dff = num2cell(dnt_dff', 2);
        roi_id  = string(begonia.util.make_uuids(length(signal_donut_dff)));
        short_name = replace(roi_table.short_name(ns_idx),"NS","NS-dnt");
        type = repmat("NS-dnt",length(short_name),1);
        f0 = dnt_f0';
        donut_dff = table(short_name,roi_id,type,signal_donut_dff,f0);
        ts.save_var("donut_dff",donut_dff);
    else
        ns_dff = [];
        ns_f0 = [];
    end

    np_idx =  roi_signal_raw.channel == 2 & roi_signal_raw.type ~= "NS";
    if any(np_idx)
        np = signal(np_idx,:);
        [np_dff,np_f0] =  glyr.img.get_dff_roi(np,"neuron",dt,0);
        np_dff = num2cell(np_dff', 2);
    else
        np_dff = [];
        np_f0 = [];
    end

    % dff
    signal_dff = cell(height(roi_table),1);
    signal_dff(ast_idx) = ast_dff;
    signal_dff(ns_idx) = ns_dff;
    signal_dff(np_idx) = np_dff;

    % f0
    f0 = zeros(height(roi_table),1);
    f0(ast_idx) = ast_f0;
    f0(ns_idx) = ns_f0;
    f0(np_idx) = np_f0;

    % create a joinable output table:
    roi_id = roi_table.roi_id;
    roi_signals_dff = table(roi_id, signal_dff,f0);

    ts.save_var("roi_signals_dff");

    % Just to not change the other scripts/functions, save ns dff in a
    % separate table (now it will be the same as in signal_dff)
    ns_subtracted = repmat({nan(1, ts.frame_count)}, height(roi_table), 1);
    ns_subtracted(ns_idx) =  ns_dff;
    signal_subtracted_dff = ns_subtracted;
    roi_signals_subtracted = table(roi_id,signal_subtracted_dff);
    ts.save_var('roi_signals_dff_subtracted',roi_signals_subtracted)

end
log(1,"Done!")
end