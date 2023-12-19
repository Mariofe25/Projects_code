function evs = peak_finder(tab_signals,parameters,fs,window,gtx)

if nargin < 4, gtx = 2.5; end
if nargin < 3, window = 60; end
if nargin < 2, fs = 10; end

import begonia.logging.backwrite
% Calcium traces
signals = horzcat(tab_signals.trace{:});

% % Denoise signals (remove some frequency bands)
% signals(1,:) = signals(2,:);
% signals(end,:) = signals(end-1,:);
signals(isnan(signals)) = 0;
dsignals = zeros(size(signals,1),size(signals,2));
for i = 1:size(signals,2)
    % try
    %     dsignals(:,i) = Pac.img.mra_dnoise(signals(:,i),9);
    % catch
        dsignals(:,i) = sgolayfilt(signals(:,i),1,11);
    % end
end

% f02 = zeros(size(d_signal2,1),1);
% df2 = zeros(size(d_signal2,1),size(d_signal2,2));
% for i = 1:size(d_signal2,1)
%     f02(i) = prctile(d_signal2(i,:),20);
%     df2(i,:) = (d_signal2(i,:) - f02(i))./f02(i);
% end
% thr = gtx*min(movstd(df,60*fs,[],2),[],2);
% % thr2 = gtx*std(df,[],2);
%
% sigma = std(df,[],2);
% mu = prctile(df,90,2);
% % mu = mean(df,2);
% I = df > mu;
% dt = 0.1;
% I = begonia.util.broaden_positives(I, dt,3);
% thr = zeros(size(I,1),1);
% for i = 1:size(df,1)
%  thr(i) = std(df(i,~I(i,:)));
% end

% Threshold for finding peaks (baseline + gtx* std baseline). Baseline is
% defined as the minimum x sec average of the trace. Std of that window is
% taken. (If the time winfow is too short is posibble that the baseline is
% negative and/or the std is very low, which translates in an increase of
% super small peaks detected.)
[base,base_idx] =  min(movmean(dsignals,window*fs));
nbase = base < 0;
base(nbase) = 0;
dev = movstd(dsignals,window*fs);
base_idx = base_idx';
base = base';
base_std = zeros(size(base_idx,1),1);
for i = 1:length(base_idx)
    base_std(i) = dev(base_idx(i),i);
end
thr = base + gtx*base_std;
thr(thr < 0.05) = 0.07;


% if do_prct
%     lows = prctile(df,50,2);
%     base_idx = df < lows;
%     dff = df;
%     dff(~base_idx) = NaN;
%     sigma = std(dff,[],2,"omitnan");
%     gtx = 3;
%     thr = gtx*sigma;
%
%     % base2std = base./base_std;
%     % base2std(nbase) = base_std(nbase);
%     %
%     % % low base, high std --> normal thr does not take low peaks
%     %
%     % thrs = repmat(2.5,length(base),1);
%     % thrs(base2std < 0.1 & base_std < 0.1) = 2;
% else
%     thr = base + gtx*base_std;
%     thr(thr < 0.1) = 0.1;
% end

% Find events 
if unique(tab_signals.channel) == 1, roi = 'Astrocyte'; else roi = 'Neuron';end
evs = cell(size(dsignals,2),1);
for j = 1:size(dsignals,2)
    backwrite(2,'%s ROIs:%d/%d',roi,j,size(dsignals,2))

    trace = dsignals(:,j);
    [pks,locs,widths,proms] = findpeaks(trace,"MinPeakHeight",thr(j)*1.25,"MinPeakProminence",thr(j));%,...
    %"MinPeakDistance",3*fs);

    % rmv_pks = pks < 0.2;
    % pks(rmv_pks) = []; locs(rmv_pks) = []; widths(rmv_pks) = []; proms(rmv_pks) = [];

    if isempty(pks)
        continue
    end

    peaks = [];
    start = [];
    ended = [];

    % Events characteristics and filtering
    for i = 1:length(pks)
        % peaks(i).roi_id = tab_signals.roi_short_name(j);
        peaks(i).x = (locs(i)/fs);
        peaks(i).x_idx = locs(i);
        peaks(i).y = trace(peaks(i).x_idx);
        peaks(i).y_filt = pks(i);
        peaks(i).prominance = proms(i);
        peaks(i).width_half = widths(i);
        peaks(i).width_half_sec = widths(i)/fs;

        %% Calculate the width.

        % onset peaks
        start(i) = Pac.img.caterpie_start(trace,locs(i),thr(j),fs);

        % end of peaks
        ended(i) = Pac.img.caterpie_end(trace,locs(i),thr(j),fs);

        % Start and end of peaks in units of x.
        peaks(i).x_start_idx = start(i);
        peaks(i).x_end_idx = ended(i);
        peaks(i).x_start = start(i)/fs;
        peaks(i).x_end = ended(i)/fs;
        peaks(i).width = peaks(i).x_end - peaks(i).x_start;
        pk = trace(peaks(i).x_start_idx:peaks(i).x_idx);
        peaks(i).x_threshold_idx = find(pk >= thr(j),1,'first') + peaks(i).x_start_idx - 1;
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

    I = [peaks.y_filt] - trace([peaks.x_start_idx])' < 0.15;
    if any(I)
        peaks(I) = [];
    end
    if isempty(peaks)
        continue;
    end


    %% Find multipeaks.
    for i = 1:length(peaks)
        peaks(i).type = 'singlepeak';
        peaks(i).n_peaks = 1;
    end

    % Peaks within anothers duration become multipeaks, by sorting by
    % amplitude the smallest peaks are deleted first.

    [~,I] = sort([peaks.y]);
    for i = I
        % If there is a peak within this peak, make peak i a multipeak and
        % mark peak j as a 'subpeak'.
        for e = I
            if i == e; continue; end
            if peaks(e).x > peaks(i).x_start && peaks(e).x < peaks(i).x_end
                peaks(e).type = 'to_be_deleted';
                peaks(i).type = 'multipeak';
                peaks(i).n_peaks = peaks(i).n_peaks + 1;
            end

            if peaks(e).x_start <= peaks(i).x_start && peaks(e).x > peaks(i).x_end
                peaks(e).type = 'to_be_deleted';
                peaks(i).type = 'multipeak';
                peaks(i).x_end = peaks(e).x_end;
                peaks(i).x_end_idx = peaks(e).x_end_idx;
                peaks(i).n_peaks = peaks(i).n_peaks + 1;
            end

        end
    end

    I = strcmp({peaks.type},'to_be_deleted');
    if any(I)
        peaks(I) = [];
    end

    % look for multipeaks witihin the singlepeaks in the trace that is less
    % smoothed
    for i = 1:length(peaks)
        if string(peaks(i).type) == "singlepeak"
            seg = trace(peaks(i).x_start_idx:peaks(i).x_end_idx);
            m_p = islocalmax(seg,"MinProminence",0.15);
            m_p = seg(m_p) > 0.2 & seg(m_p) > thr(j);
            if sum(m_p) > 1
                peaks(i).type = 'multipeak';
            end
        end
    end


    %% Calculate AUC and decide plateau
    for i = 1:length(peaks)
        vec = dsignals(peaks(i).x_start_idx:peaks(i).x_end_idx,j);
        vec(vec < 0) = 0;

        % AUC
        peaks(i).auc = trapz(vec)/fs;

        % % Decide plateau
        % ratio = sum(vec)/max(vec)/length(vec);
        % p = peaks(i).x_idx;
        % ptoff = round(mean(diff(trace([p,p+5*fs-1]))/(1/fs)),2) == 0;
        % %ptoff = round(mean(diff(trace(p:p+5*fs-1))/(1/fs)),2) == 0;
        % if ptoff && ratio > parameters.astrocyte_plateau_min_ratio &&...
        %         peaks(i).width_half_sec > parameters.astrocyte_plateau_min_width
        %     if string(peaks(i).type) ~= "multipeak"
        %         peaks(i).type = 'plateau';
        %     end
        % end
    end

    evs{j} = peaks;
    % 
    % % plot
    % fig =  figure("Position",[680 701 1200 297]); plot(trace)
    % % title([j, '', peaks(1).roi_id])
    % hold on
    % yline(thr(j))
    % colors = containers.Map({'singlepeak','multipeak','plateau'},["r","m","g"]);
    % for i = 1:length(peaks)
    %     plot(peaks(i).x_idx, trace(peaks(i).x_idx),'bo')
    %     plot(peaks(i).x_start_idx:peaks(i).x_end_idx,...
    %         trace(peaks(i).x_start_idx:peaks(i).x_end_idx),"Color",'r')%...
    %         %colors(peaks(i).type))
    % end
    % L1 = plot(nan, nan, 'color', 'r');
    % L2 = plot(nan, nan, 'color', 'm');
    % L3 = plot(nan, nan, 'color', 'g');
    % % legend([L1, L2, L3], {'singlepeak', 'multipeak','platoau'})
    % % print(fig,"/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/Plots/peak_detection/" + j,...
    %     "-r300","-dpng")
    % delete(fig)

end
end