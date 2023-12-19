function peaks_tot = find_events_neu(traces,fs,parameters,do_correction)
if nargin < 4, do_correction = false;end
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

%traces = detrend(traces);
traces_hp = traces;

% % Replace nan with 0 for the filtering.
% I = isnan(traces_hp(:));
% traces_hp(I) = 0;
% begonia.logging.log(2,'Highpass filtering neuron traces.');
% traces_hp = traces_hp - convn(traces_hp,filter,'same');
% % Insert the nans back.
% traces_hp(I) = nan;
%
% sigmas = nanstd(traces_hp,[],1) * parameters.neuron_sigma_detection;

noise = movstd(traces_hp,5*fs);
sigmas = min(noise) * parameters.neuron_sigma_detection;

% Smooth traces
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

if do_correction
    neg_traces = traces_hp(traces_hp < 0);
    mean_negts = mean(neg_traces);
    traces_hp = traces_hp - mean_negts;
end

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
        'MinPeakHeight',sigma,...
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
        % onset
        x_start_idx = find(round(trace(1:peaks(i).x_idx),2) <= ref,1,'last');
        
        if peaks(i).x_idx - x_start_idx > 90
            tr_pk = trace(1:peaks(i).x_idx);
            m = islocalmin(tr_pk,"MinProminence",sigma/2,...
                'MinSeparation',15);
            is_min = tr_pk <= sigma/2;
            m = find(m & is_min);
            if numel(m) > 1
                [~,min_idx] = min(length(tr_pk) - m);
                sp = m(min_idx);
            else
                sp = m;
            end
            
            % in case the onset is too far from the peak, calculate onset w/
            if  ~isempty(sp) && peaks(i).x_idx - sp < 90
                x_start_idx = sp;
            end
        end
        
        % end point
        x_end_idx = find(round(trace(peaks(i).x_idx:end),2) <= ref,1,'first') + peaks(i).x_idx - 1;
        if x_end_idx -  peaks(i).x_idx > 200
            rt_pk = trace(peaks(i).x_idx:end);
            m = islocalmin(rt_pk,"MinProminence",abs(sigma)/2,...
                'MinSeparation',15);
            is_min = rt_pk <= sigma/2;
            m = find(m & is_min);
            if numel(m) > 1
                [~,min_idx] = min(m - peaks(i).x_idx);
                ep = m(min_idx) + peaks(i).x_idx - 1;
            else
                ep = m + peaks(i).x_idx - 1;
            end
            
            if ~isempty(ep) && ep - peaks(i).x_idx < 150
                x_end_idx = ep;
            end
        end
        
        % Edge cases.
        if isempty(x_start_idx); x_start_idx = 1; end
        
        if isempty(x_end_idx); x_end_idx = length(trace); end
        
        % Start and end of peak in units of x.
        peaks(i).x_start_idx = x_start_idx;
        peaks(i).x_end_idx = x_end_idx;
        peaks(i).x_start = x_start_idx/fs;
        peaks(i).x_end = x_end_idx/fs;

        peaks(i).width = peaks(i).x_end - peaks(i).x_start;
        pk = trace(peaks(i).x_start_idx:peaks(i).x_idx);
        peaks(i).x_threshold_idx = find(pk >= sigma,1,'first') + peaks(i).x_start_idx -1;
        peaks(i).x_threshold = peaks(i).x_threshold_idx/fs;
        
        %         peaks(i).x_onset_idx =  x_onset_idx;
        %         peaks(i).x_onset = x_onset_idx/fs;
        %         peaks(i).x_off_idx =  x_off_idx;
        %         peaks(i).x_off = x_off_idx/fs;
        
        if x_start_idx == x_end_idx
            peaks(i).auc = 0;
        else
            vec = traces(x_start_idx:x_end_idx,trace_idx);
            vec(vec < 0) = 0;
            peaks(i).auc = trapz(vec)/fs;
        end
    end
    
    % Remove too short peaks.v
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
    
    % Remove peaks which onset to peak is too long    
%     I = [peaks.x_idx] - [peaks.x_start_idx] > 90;
%     if any(I)
%         peaks(I) = [];
%     end
%     if isempty(peaks)
%         continue;
%     end
    
    % Remove pekas which peak idx is the threshold idx
    I = [peaks.x_threshold_idx] + 1 >= [peaks.x_idx];
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