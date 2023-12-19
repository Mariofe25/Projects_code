function peaks_tot = find_events_neu(traces,fs,parameters)
% Modify from Daniel/Rune
if isrow(traces)
    traces = reshape(traces,[],1);
end
if isempty(traces)
    peaks_tot = [];
    return;
end

%% Calculate detection threshold for each trace.
filter = begonia.util.gausswin(parameters.neuron_sigma_highpass_window_1*fs);

traces_hp = traces;
% Replace nan with 0 for the filtering. 
I = isnan(traces_hp(:));
traces_hp(I) = 0;
begonia.logging.log(2,'Highpass filtering neuron traces.');
traces_hp = traces_hp - convn(traces_hp,filter,'same');
% Insert the nans back. 
traces_hp(I) = nan;

sigmas = nanstd(traces_hp,[],1) * parameters.neuron_sigma_detection;
%% Smooth traces
begonia.logging.log(2,'Smoothing neuron traces.');
filter = begonia.util.gausswin(parameters.neuron_sigma_smoothing*fs);
traces = convn(traces,filter,'same');
%% high pass filter all traces
filter = begonia.util.gausswin(parameters.neuron_sigma_highpass_window_2*fs);

traces_hp = traces;
% Replace nan with 0 for the filtering. 
I = isnan(traces_hp(:));
traces_hp(I) = 0;
begonia.logging.log(2,'Highpass filtering neuron traces.');
traces_hp = traces_hp - convn(traces_hp,filter,'same');
% Insert the nans back. 
traces_hp(I) = nan;
%% Find peaks
peaks_tot = {};

% For printing
order = floor(log10(size(traces,2))) + 1;
order = num2str(order);
str_template = ['Neuron    ROI (%',order,'d/%',order,'d)'];
%begonia.logging.backwrite();

for trace_idx = 1:size(traces_hp,2)
    str = sprintf(str_template,trace_idx,size(traces_hp,2));
    begonia.logging.backwrite(2,str);
    trace = traces_hp(:,trace_idx);
    trace(isnan(trace)) = [];
    if isempty(trace); continue; end
    
    sigma = sigmas(trace_idx);
    
    warning off
    [pks,locs,widths,proms] = findpeaks(trace,...
        'MinPeakProminence', sigma, ...
        'MinPeakHeight', sigma, ...
        'WidthReference','halfheight');
    warning on
    
    if isempty(pks)
        continue
    end
    
    peaks = [];
    
    for i = 1:length(pks)
        peaks(i).x = (locs(i)/fs);
        peaks(i).x_idx = locs(i);
        peaks(i).y = traces(peaks(i).x_idx,trace_idx);
        peaks(i).y_filt = pks(i);
        peaks(i).prominance = proms(i);
        peaks(i).width_half = widths(i);
        peaks(i).trace_idx = trace_idx;

        % Calculate the width.
        ref = 0;
        x_start_idx = find(trace(1:peaks(i).x_idx) <= ref,1,'last');
        x_end_idx = find(trace(peaks(i).x_idx:end) <= ref,1,'first') + peaks(i).x_idx - 1;

        % Edge cases.
        if isempty(x_start_idx); x_start_idx = 1; end
        if isempty(x_end_idx); x_end_idx = length(trace); end

        % Start and end of peak in units of x. 
        peaks(i).x_start_idx = x_start_idx;
        peaks(i).x_end_idx = x_end_idx;
        peaks(i).x_start = x_start_idx/fs;
        peaks(i).x_end = x_end_idx/fs;
        peaks(i).width = peaks(i).x_end - peaks(i).x_start;
        if x_start_idx == x_end_idx
            peaks(i).auc = 0;
        else
            vec = traces(x_start_idx:x_end_idx,trace_idx);
            vec(vec < 0) = 0;
            peaks(i).auc = trapz(vec)/fs;
        end
    end
    
    % Remove too short peaks.
    I = [peaks.width] < parameters.neuron_min_peak_width;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    % Remove too long peaks.
    I = [peaks.width] > parameters.neuron_max_peak_width;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    % Define all peaks as single peaks. 
    for i = 1:length(peaks)
        peaks(i).type = 'singlepeak';
        peaks(i).n_peaks = 1;
    end
    
    % Find peaks inside other peaks and remove them.
    % Sort by height so tallest peak remains. 
    [~,I] = sort([peaks.y]);
    for i = I
        for j = I
            if i == j
                continue; 
            end
            
            if peaks(j).x >= peaks(i).x_start && peaks(j).x <= peaks(i).x_end
                peaks(j).type = 'to_be_removed';
                peaks(i).type = 'singlepeak';
            end
        end
    end
    I = strcmp({peaks.type},'to_be_removed');
    if any(I)
        peaks(I) = [];
    end
    
    peaks_tot{trace_idx} = peaks;
end
peaks_tot = cat(2,peaks_tot{:});
end