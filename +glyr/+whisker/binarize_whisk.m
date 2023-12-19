function  whisking =  binarize_whisk(trials)
import begonia.logging.*
n = 0;
for trial = trials
    n = n + 1;
    backwrite(1,'Whisker trace segmentation from trial: %d/%d',n,numel(trials))
    whisker = trial.load_var('whisking_trim');
    whisk_trace = whisker.Data;
    dt = whisker.Time(2) - whisker.Time(1);

    % smooth, find baseline and classify:
    whisk_trace = movmean(whisk_trace, 10);
    baseline = prctile(whisk_trace,1);   % mode(whisk_trace);
    whisking = (whisk_trace - baseline) > 1.5;  % from Daniel / Klas / sleep project

    % When the mouse is moving(motion/run) the baseline is too high and many
    % parts of the whisker trace are not considered whisking, when they
    % should. Since it is known that when the mouse moves it whisks, assign
    % motio/run segments to whisking status
    loc = trial.load_var("locomotion_tab");
    motion = loc(loc.locomotion_state == "Motion" |...
        loc.locomotion_state == "Run",:);
    w = false(whisker.TimeInfo.Length,1);
    for i = 1:height(motion)
        w(whisker.Time >= motion.start_sec(i) & ...
            whisker.Time <= motion.end_sec(i)) = true;
    end

    % Combine threshold trace with motion trace
    whisking = whisking | w;


    % if segments between whisking segments are very short (< 0.5s),
    % include in the whisking state
    whisk_segments = bwconncomp(~whisking).PixelIdxList;
    seg_length = cellfun(@length,whisk_segments);
    whisk_segments = whisk_segments(seg_length < 0.5/dt);
    whisk_idx = vertcat(whisk_segments{:});
    whisking(whisk_idx) = 1;

    % whisking duration should last at least 400 ms;
    cont_segments = bwconncomp(whisking).PixelIdxList;
    frames_1s = round(0.4/dt);
    seg_lengths = arrayfun(@(s) length(s{:}), cont_segments);
    cont_segments = cont_segments(seg_lengths < frames_1s);
    whisking_idx = vertcat(cont_segments{:});
    whisking(whisking_idx) = false;


    % whisking tab
    whisk = repmat(categorical(""),length(whisking),1);
    whisk(~whisking) = categorical("No Whisking");
    whisk(whisking) = categorical("Whisking");
    %     whisk(whisking_idx) = categorical("Uncertain");

    w_type = double(whisk)';
    w_change = find(ischange(w_type));

    dt = whisker.TimeInfo.End/whisker.TimeInfo.Length;

    whisk_state = [whisk(1);whisk(w_change)];
    start_frame = [1;w_change'];
    end_frame = [w_change' - 1;length(whisk)];
    deltat = repmat(dt,numel(whisk_state),1);
    start_sec = (start_frame * dt) - dt;
    end_sec = (end_frame * dt) - dt;
    sec_duration = end_sec - start_sec;

    w_tab = table(whisk_state,start_frame,end_frame,deltat,...
        start_sec,end_sec,sec_duration);

    % whisking duration should last at least 400 ms;
    cont_segments = bwconncomp(whisking).PixelIdxList;
    frames_1s = round(0.4/dt);
    seg_lengths = arrayfun(@(s) length(s{:}), cont_segments);
    cont_segments = cont_segments(seg_lengths > frames_1s);
    whisking_idx = vertcat(cont_segments{:});
    whisking = false(length(whisking),1);
    whisking (whisking_idx) = true;

    % Convert to timeseries
    %     whisking = timeseries(whisking,whisker.Time);

    % save it
    whisk = whisker;
    whisk.Data = whisking;
    whisk.Name = 'binarized whisking';

    trial.save_var('whisking_tab',w_tab)
    trial.save_var('whisking',whisk)
end
log(1,'Whisking trace segmentation of %d trials completed!',numel(trials))
end