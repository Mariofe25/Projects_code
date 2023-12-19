function  whisking =  binarize_whisk(trials)

% CAT_OTHER = categorical("other");
% CAT_WHISK = categorical("whisk");

for trial = trials
    
    whisker = trial.load_var('whisking_trim');
    whisk_trace = whisker.Data;
    
    % smooth, find baseline and classify:
    whisk_trace = movmean(whisk_trace, 10);
    baseline = mode(whisk_trace);
    whisking = (whisk_trace - baseline) > 1.5;    % from Daniel / Klas / sleep project
    
    whisk = whisker;
    whisk.Data = whisking;
    whisk.Name = 'binarized whisking';
    
    trial.save_var('whisking',whisk)
    
    %     whisk_cat = repmat(CAT_OTHER, length(whisk_trace), 1);
    %     whisk_cat(whisking) = CAT_WHISK;    
end
end