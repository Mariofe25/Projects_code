function ts2mark(tss)
% Find the tseries of each FoV with more activity.
% It takes the astrocytes channel trace and look for the max value. The
% tseries with higher values are tagged.

fovs = tss.load_var('FoV');
fovs = [fovs{:}];
n_fovs = unique(fovs);
disp(numel(n_fovs) + "  FoVs found. Tagging tseries with more activity of each FoV...")
for i = 1:length(n_fovs)
    disp("FoV: " + n_fovs(i))
    ts_idx = ismember(fovs,n_fovs(i));
    ts = tss(ts_idx);
    disp(length(ts) + " Tseries.")
    if numel(ts) == 1
        ts.save_var('to_mark',true)
        disp(ts.name + " tagged.")
    else
        ch_max = zeros(1,length(ts));
        for j = 1:length(ts)
            try
                channel_trace = ts(j).load_var('channel_traces');
            catch
                channel_trace = begonia.processing.roi.extract_channel_traces(ts(j));
            end
            %ch_t = sgolayfilt(channel_trace.Data(45:end,1),1,29);
            ch_t = channel_trace.Data(45:end,1);% sgolayfilt(X,ORDER,FRAMELEN)
            ch_f0 = mode(round(ch_t));
            ch_dff = (ch_t - ch_f0)/ch_f0;
            [ch_max(j),max_idx(j)] = max(ch_dff);
            %             is_max = find(islocalmax(ch_t));
            %             is_peak(j) = ismember(max_idx(j),is_max);
            %
            %peaks = islocalmax(ch_t,"MinProminence",threshold);
            %n_peaks(j) = sum(peaks);
        end
        [~,id] = max(ch_max);

        % tag tseries that will be used to draw the rois mask
        mark = true;
        ts(id).save_var('to_mark',mark)
        disp(ts(id).name + " tagged.")
    end
end
end