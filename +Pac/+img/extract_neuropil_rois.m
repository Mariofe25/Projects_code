function extract_neuropil_rois(tss)
import begonia.logging.log
for ts = tss
    log(1, "Extracting doughnut signals from: " + ts.name)
    begonia.processing.roi.extract_neuron_doughnut_signals(ts,8,3);
end
end