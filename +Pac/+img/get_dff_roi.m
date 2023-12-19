function [deltaFoF,F0] = get_dff_roi(traces,roi_type,dt,do_subtraction,alpha,signals_donut)
if nargin < 6, signals_donut = []; end
if nargin < 5, alpha = 0.7; end

if roi_type == "neuron" && do_subtraction
    % Subtract neuropil signal from neuron soma rois
    np_sub = alpha*signals_donut'; % some np do not have mas, so the calculated signal is nan;
    np_sub(isnan(np_sub)) = 0;
    fluoTraces = traces' - np_sub;
    fluoTraces = fluoTraces + abs(min(fluoTraces));
    % fluoTraces = hampel(fluoTraces,4,2);
elseif roi_type == "neuron" && ~do_subtraction
    fluoTraces = traces';
    % fluoTraces = hampel(fluoTraces,4,2);
else
    fluoTraces = traces';
end

% detrend signal
fluoTraces = correct_drift(fluoTraces,dt);

fps = round(1/dt);

% if roi_type == "neuron"
%     wd = 5 * fps;
% else
%     wd = 10 * fps;
% end
%
% % smooth trace
% ftraces = sgolayfilt(fluoTraces,1,wd+1);

% % filter raw signal
% if roi_type ~= "neuron"
%     d_signal = zeros(size(fluoTraces,1),size(fluoTraces,2));
%     for i = 1:size(fluoTraces,2)
%         try
%             d_signal(:,i) = Pac.mra_dnoise(fluoTraces(:,i),9);
% 
%         catch
%             d_signal(:,i) =  sgolayfilt(fluoTraces(:,i),1,31);
%         end
%     end
% else
%     d_signal = fluoTraces;
% end

% Relative signal ∆F/F
if roi_type == "neuron", pr = 20; else, pr = 10;end

% if do_multi_base
% for i = 1:size(fluoTraces,2)
% 
%     % segment the data in chuncks of 2 min
%     ff{i} = reshape(fluoTraces(:,i),[],5);
% 
%     % 25th percentile of chuncks
%     pp{i} = prctile(ff{i},25);
% 
%     % max difference from lowest 25th percentile
%     pp_md(i) = max(pp{i} - min(pp{i}))/min(pp{i});
% end
% else
% end

F0 = prctile(fluoTraces,pr); % baseline
deltaFoF = (fluoTraces - F0)./F0;


end

function fluoTraces = correct_drift(fluoTraces,dt)
% time vector
drift_trace_t = repmat((0:dt:length(fluoTraces)*dt - dt)',1,size(fluoTraces,2));
drift_correction_trace_t = num2cell(drift_trace_t,1);

% remove outliers (usually panactivations)
rr = sgolayfilt(fluoTraces,1,31);
sigma = std(rr);
mu = mean(rr);
I = rr > mu + 2*sigma;
I = begonia.util.broaden_positives(I, dt,5);
drift_trace_t = num2cell(drift_trace_t,1);
rr = num2cell(rr,1);
for i = 1:size(rr,2)
    drift_trace_t{i}(I(:,i)) = [];
    rr{i}(I(:,i)) = [];
end

% Drift fitting
coeff = cellfun(@(s,g) polyfit(s,g,1),drift_trace_t,rr,...
    'UniformOutput',false);
drift_correction_trace = cell(1,46);
for i = 1:size(rr,2)
    drift_correction_trace{i} = coeff{i}(end)./polyval(coeff{i},...
        drift_correction_trace_t{i});
end
drift_correction_trace = horzcat(drift_correction_trace{:});

% only correct negative drift (photobleaching)
idx = drift_correction_trace(1,:) > drift_correction_trace(end,:);
drift_correction_trace(:,idx) = 1;

% correction
fluoTraces = fluoTraces.*drift_correction_trace;
end