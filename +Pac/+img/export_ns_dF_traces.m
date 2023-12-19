function export_ns_dF_traces(tss,do_denoise)
if nargin < 2, do_denoise = false; end
import begonia.logging.*
n = 0;
for ts = tss
    n = n + 1;
    backwrite(1,'Exporting ∆F/F traces for spike probability inference.TSeries: %d/%d', n, length(tss))

    path = "/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/ns_dF_traces";

    if do_denoise
        path = fullfile(path,"denoised");
        dff = ts.load_var('denoised_ns_dff');
        dF_traces = vertcat(dff.signal_denoised_dff{:});
    else
        dff = ts.load_var('roi_signals_dff_subtracted');
        dF_traces = vertcat(dff.signal_subtracted_dff{:});
    end

    dF_traces(all(isnan(dF_traces'))',:) = [];

    name = ts.name;
    filename = name + "_dF_traces.mat";
    filename = fullfile(path,filename);
    begonia.path.make_dirs(filename)

    save(filename,"dF_traces")
end
log(1,"Export done!")
end