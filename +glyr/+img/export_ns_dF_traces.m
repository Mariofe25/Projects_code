function export_ns_dF_traces(tss,do_smoothing)
if nargin < 2, do_smoothing = false; end
for ts = tss
    dff = ts.load_var('roi_signals_dff_subtracted');
    dF_traces = vertcat(dff.signal_subtracted_dff{:});
    
    virus = ts.load_var('virus');
    exp = ts.load_var('drug');
    path = "/Volumes/GlyR/dff/"; 
    
    % Remove non NS rois
    dF_traces(all(isnan(dF_traces'))',:) = [];

    if do_smoothing
        dF_traces = sgolayfilt(dF_traces,1,15,[],2);
        path = fullfile(path,"smooth_");
    end

    path = path + virus + "/" + exp;
    name = ts.name;
    filename = name + "_dF_traces.mat";
    filename = fullfile(path,filename);
    begonia.path.make_dirs(filename)

    save(filename,"dF_traces")
end
end