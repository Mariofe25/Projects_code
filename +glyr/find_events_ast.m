function peaks_tot = find_events_ast(traces,fs,parameters,do_correction)
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
filter = begonia.util.gausswin(parameters.astrocyte_sigma_highpass_window_1*fs);

traces_hp = traces;
% in case there are many negative values in the trace

% % Replace nan with 0 for the filtering.
% I = isnan(traces_hp(:));
% traces_hp(I) = 0;
% begonia.logging.log(2,'Highpass filtering astrocyte traces');
% traces_hp = traces_hp - convn(traces_hp,filter,'same');
% % Insert the nans back.
% traces_hp(I) = nan;
% sigmas = std(traces_hp,'omitnan')* parameters.astrocyte_sigma_detection;

% Calculate threshold(sigma)

noise = movstd(traces_hp,10*fs);
sigmas = min(noise) * parameters.astrocyte_sigma_detection;


%% Smooth traces
begonia.logging.log(2,'Smoothing astrocyte traces');
filter = begonia.util.gausswin(parameters.astrocyte_sigma_smoothing*fs);
traces = convn(traces,filter,'same');
%% high pass filter all traces
filter = begonia.util.gausswin(parameters.astrocyte_sigma_highpass_window_2*fs);
%
traces_hp = traces;
% Replace nan with 0 for the filtering.
% I = isnan(traces_hp(:));
% traces_hp(I) = 0;
%
%
% % Do the highpass filtering in chunks.
% c = begonia.util.Chunker(traces_hp,'chunk_axis',2,'chunk_size',5000);
% tmp = {};
% for i = 1:c.chunks
%     str = sprintf('Highpass filtering astrocyte traces (chunk %d/%d)',i,c.chunks);
%     begonia.logging.log(2,str);
%     I_mat = c.chunk_indices(i);
%     tmp{i} = traces_hp(I_mat{:});
%     tmp{i} = tmp{i} - convn(tmp{i},filter,'same');
% end
% traces_hp = cat(2,tmp{:});
%
% % Insert the nans back.
% traces_hp(I) = nan;

if do_correction
    neg_traces = traces_hp(traces_hp < 0);
    mean_negts = mean(neg_traces);
    traces_hp = traces_hp - mean_negts;
end

%% For printing
order = floor(log10(size(traces,2))) + 1;
order = num2str(order);
str_template = ['Astrocyte ROI (%',order,'d/%',order,'d)'];
%begonia.logging.backwrite(2,str_template);

%%
peaks_tot = {};
for trace_idx = 1:size(traces,2)
    str = sprintf(str_template,trace_idx,size(traces_hp,2));
    begonia.logging.backwrite(2,str);
    trace = traces_hp(:,trace_idx);
    trace(isnan(trace)) = [];
    if isempty(trace); continue; end
    
    sigma = sigmas(trace_idx);
    
    warning off
    [pks,locs,widths,proms] = findpeaks(trace,...
        'MinPeakProminence',sigma, ...
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
        peaks(i).width_half_sec = widths(i)/fs;
        peaks(i).trace_idx = trace_idx;
        
        t = trace;
        % Calculate the width.
        ref = 0;
        
        if ~any(trace(1:peaks(i).x_idx) <= 0)
            trace = detrend(trace);
            %ref = prctile(trace(1:peaks(i).x_idx),10);
        end
        
        % onset
        x_start_idx = find(round(trace(1:peaks(i).x_idx),2) <= ref,1,'last');
        if isempty(x_start_idx); x_start_idx = 1; end
        
        tr_pk = trace(1:peaks(i).x_idx);
        m = islocalmin(tr_pk,"MinProminence",sigma/2,...
            'MinSeparation',30);
        is_min = tr_pk <= sigma;
        m = find(m & is_min);
        if numel(m) > 1
            [~,min_idx] = min(length(tr_pk) - m);
            sp = m(min_idx);
        else
            sp = m;
        end
        
        % in case the onset is too far from the peak, calculate onset w/
        if (x_start_idx == 1 && ~isempty(sp)) || (peaks(i).x_idx - x_start_idx > 300 && ~isempty(sp))
            x_start_idx = sp;
        elseif i > 1 &&  x_start_idx <= peaks(i-1).x_start_idx
            x_start_idx = sp;
        end
       
         trace = t;
        % end point
        if ~any(trace(peaks(i).x_idx:end) <= 0)
            trace = detrend(trace);
            %ref = prctile(trace(1:peaks(i).x_idx),10);
        end
        x_end_idx = find(round(trace(peaks(i).x_idx:end),2) <= ref,1,'first') + peaks(i).x_idx - 1;
        if isempty(x_end_idx); x_end_idx = length(trace); end
        rt_pk = trace(peaks(i).x_idx:end);
        m = islocalmin(rt_pk,"MinProminence",abs(sigma) /2,...
            'MinSeparation',30);
        is_min = rt_pk <= sigma/2;
        m = find(m & is_min);
        if numel(m) > 1
            [~,min_idx] = min(m - peaks(i).x_idx);
            ep = m(min_idx) + peaks(i).x_idx - 1;
        else
            ep = m + peaks(i).x_idx - 1;
        end
        
        if ~isempty(ep) && x_end_idx == length(trace) || x_end_idx - peaks(i).x_idx > 600
            x_end_idx = ep;
        end
        
        
        % Edge cases.
        if isempty(x_start_idx); x_start_idx = 1; end
        if isempty(x_end_idx); x_end_idx = length(trace); end
        
        
        trace = t;
        % Start and end of peak in units of x.
        peaks(i).x_start_idx = x_start_idx;
        peaks(i).x_end_idx = x_end_idx;
        peaks(i).x_start = x_start_idx/fs;
        peaks(i).x_end = x_end_idx/fs;
        peaks(i).width = peaks(i).x_end - peaks(i).x_start;
        pk = trace(peaks(i).x_start_idx:peaks(i).x_idx);
        peaks(i).x_threshold_idx = find(pk >= sigma,1,'first') + peaks(i).x_start_idx - 1;
        peaks(i).x_threshold = peaks(i).x_threshold_idx/fs;
        
    end
    
    % Remove too short peaks.
    I = [peaks.width] < parameters.astrocyte_min_peak_width;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    % Remove too long peaks.
    I = [peaks.width] > parameters.astrocyte_max_peak_width;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    % Remove peaks at start
    I = [peaks.x_start] < 1;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    % Remove too low peaks.
    I = [peaks.y_filt] < parameters.astrocyte_min_peak_height;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    %     I = trace([peaks.x_threshold_idx]) - trace([peaks.x_start_idx]) < sigma/2;
    %     if any(I)
    %         peaks(I) = [];
    %     end
    %     if isempty(peaks)
    %         continue;
    %     end
    
    % Remove low peaks
    I = [peaks.y_filt] - trace([peaks.x_start_idx])' < 0.1;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end
    
    
    %% Define all peaks as single peaks first.
    for i = 1:length(peaks)
        peaks(i).type = 'singlepeak';
        peaks(i).n_peaks = 1;
    end
    
    %% Find multipeaks.
    % Peaks within anothers duration become multipeaks, by sorting by
    % amplitude the smallest peaks are deleted first.
    [~,I] = sort([peaks.y]);
    for i = I
        % If there is a peak within this peak, make peak i a multipeak and
        % mark peak j as a 'subpeak'.
        for j = I
            if i == j; continue; end
            if peaks(j).x > peaks(i).x_start && peaks(j).x < peaks(i).x_end
                peaks(j).type = 'to_be_deleted';
                peaks(i).type = 'multipeak';
                peaks(i).n_peaks = peaks(i).n_peaks + 1;
            end
            
            if peaks(j).x_start <= peaks(i).x_start && peaks(j).x > peaks(i).x_end
                peaks(j).type = 'to_be_deleted';
                peaks(i).type = 'multipeak';
                peaks(i).x_end = peaks(j).x_end;
                peaks(i).x_end_idx = peaks(j).x_end_idx;
                peaks(i).n_peaks = peaks(i).n_peaks + 1;
            end
            
        end
    end
    
    I = strcmp({peaks.type},'to_be_deleted');
    if any(I)
        peaks(I) = [];
    end
    
    %% Calculate AUC and decide plateau
    for i = 1:length(peaks)
        vec = traces(peaks(i).x_start_idx:peaks(i).x_end_idx,trace_idx);
        vec(vec < 0) = 0;
        
        % AUC
        peaks(i).auc = trapz(vec)/fs;
        
        % Decide plateau
        ratio = sum(vec)/max(vec)/length(vec);
        if ratio > parameters.astrocyte_plateau_min_ratio && peaks(i).width > parameters.astrocyte_plateau_min_width
            peaks(i).type = 'plateau';
        end
    end
    
    %% Aggregate peaks
    peaks_tot{trace_idx} = peaks;
end
peaks_tot = cat(2,peaks_tot{:});
end