function ca_latency(tss,do_save_tabs, do_save_plots, thres)
if nargin < 4, thres = "median";end
if nargin < 3 || isempty(do_save_plots), do_save_plots = true;end
if nargin < 2 || isempty(do_save_tabs), do_save_tabs = true;end
tags = tss.load_var('tags');
tags = string(tags);
% before_idx = contains(tags,'before');
% tags_before = tags(before_idx);
% tss_before = tss(before_idx);
tag = unique(tags);
for i = 1:length(tag)
    c = tag(i);
    tss_cat = tss(tags == c);
    t = tss_cat.load_var('roi_table');
    t = vertcat(t{:});
    type = t.type;
    comp = tss_cat.load_var('roi_signals_dff');
    compartments = vertcat(comp{:});
    compartments.type = type;
    
    % onset neurons
    neurons = tss_cat.load_var('channel_traces');
    neurons = cellfun(@(s) s.Data(:,1),neurons,'UniformOutput',false);
    neurons = cell2mat(neurons);
    neuron_baseline = mode(round(neurons(1:29,:),2));
    neuron_thres = neuron_baseline + 2*std(neurons(1:29,:));
    indx = zeros(1,numel(neuron_thres));
    for n = 1:size(neuron_thres,2)
        indx(n) = find(neurons(30:40,n) > neuron_thres(n),1,"first");
    end
    idx_stim = 30:40;
    neuron_onset = idx_stim(indx);
    tseries = unique(t.source_id);
    n_on = cell(length(neuron_onset),1);
    for on = 1:length(neuron_onset)
      n_on{on} = repmat(neuron_onset(on),height(t(t.source_id == tseries(on),:)),1);  
    end
    n_on = vertcat(n_on{:});
    compartments.neuron_onset = n_on;
    roi_type = unique(type);
    
    % Find onset & max astrocyte Ca2+
    for j = 1:length(roi_type)
        rr =  compartments.signal_dff(compartments.type == roi_type(j));
        neu = compartments.neuron_onset(compartments.type == roi_type(j));
        stim_idx = 30;
        neu = neu - stim_idx;
        rr = vertcat(rr{:});
        baseline = rr(:,1:29);
        min_base = min(baseline,[],2);
        rr = rr + abs(min_base);
        baseline = rr(:,15:29);
        %b= sgolayfilt(baseline,1,3,[],2);
        %b = baseline + abs(min(baseline,[],2));
        %threshold = 2.5*median(abs(baseline),2);
        base = prctile(baseline,10,2);
        switch thres
            case "median"
                threshold = 2.5*median(abs(baseline),2);
            case "2std"
                threshold = base + 2*std(baseline,0,2);
            case "3std"
                threshold = base + 3*std(baseline,0,2);
        end
        stim = rr(:,30:50);
        [max_peak_value,max_peak_time] = max(stim,[],2);
        time_to_max = max_peak_time - neu;
        baseline_onset = nan(size(stim,1),1);
        peak_onset = nan(size(stim,1),1);
        for k = 1: size(stim,1)
            try
                baseline_onset(k) = find(stim(k,:) >= threshold(k),1,"first");
                if baseline_onset(k) == max_peak_time(k)
                    baseline_onset(k) = nan;
                    max_peak_time(k) = nan;
                end
                if baseline_onset(k) == 1 && round(stim(k,baseline_onset(k)),2) < round(baseline(k,end),2)
                    baseline_onset(k) = nan;
                    max_peak_time(k) = nan;
                end
                if baseline_onset(k) > 10 || time_to_max(k) == 0
                    baseline_onset(k) = nan;
                    max_peak_time(k) = nan;
                end
                if all(stim(k,1:max_peak_time(k)) >  threshold(k))
                    peak_onset(k) = 1;
                else
                    peak_onset(k) = find(stim(k,1:max_peak_time(k)) <= threshold(k),1,"last");
                    if  peak_onset(k) - baseline_onset(k) > 5
                        baseline_onset(k) = nan;
                        max_peak_time(k) = nan;
                        peak_onset(k) = nan;
                    end
                end
            catch
                max_peak_time(k) = nan;
                continue
            end
        end
        %on = indx - 1;  the frame rate is low (1)
        time_to_onset = baseline_onset - neu;
        time_to_peak_onset = peak_onset - neu;
        time_onset_to_max = time_to_max - time_to_onset;
        time_peakonset_to_max = time_to_max - time_to_peak_onset;
        
        % Results in table
        latency = table(threshold,time_to_onset,max_peak_value,time_to_max,time_to_peak_onset,...
            time_onset_to_max,time_peakonset_to_max);
        if do_save_tabs
            path = "/Users/mariofernandez/Downloads/jarand-copy/analysis/latency/" + thres + "/tabs";
            filename = "Ca_latency-" + c + "_" + roi_type(j);
            outab = fullfile(path,filename);
            writetable(latency,outab,'FileType','spreadsheet')
        end
        
        % Plotting
        for p = 1: size(stim,1)
            fig = figure;
            plot(rr(p,:))
            tit =  sprintf(c + '\n' + "Latency Ca2+ " + roi_type(j) + p);
            title(tit)
            ylabel("df/f")
            xlabel("time(s)")
            hold on
            % max line
            if ~isnan(max_peak_time(p))
                xline(max_peak_time(p) + 29)
                % peak onset
                xline(peak_onset(p) + 29,'r--')
                % baseline_onset
                xline(baseline_onset(p) + 29,'g-.')
                legend("stim trace","max time","onset max","threshold")
                hold off
            end
            
            if do_save_plots
                path = "/Users/mariofernandez/Downloads/jarand-copy/analysis/latency/" + thres + "/Plots";
                fname = fullfile(path,c);
                if~isfolder(fname),mkdir(fname),end
                fname2 = fullfile(fname,roi_type(j));
                if ~isfolder(fname2),mkdir(fname2),end
                name = roi_type(j) + p;
                if isnan(max_peak_time(p))
                    fname3 = fullfile(fname2,"nope");
                    if~isfolder(fname3),mkdir(fname3),end
                    outpng = fullfile(fname3,name);
                else
                    outpng = fullfile(fname2,name);
                end
                print(fig, outpng, '-r300', '-dpng');
            end
            delete(fig)
        end
    end
end
end