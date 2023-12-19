function [whisker_tab_valid,whisker_tab] = find_whisker_data (tss)

% folder with whisker data
whisker_folder = '/Volumes/Whiski';
if ~isfolder(whisker_folder)
    fprintf('Whisker folder does not exist or it has been moved to other location \nLook for it\n')
    whisker_folder = uigetdir;
end

% list whisker data paths
whiskers_files = dir(whisker_folder);
w_idx = contains({whiskers_files.name},'.seq');
whiskers_files = whiskers_files(w_idx);
whiskers_file_names = {whiskers_files.name}';

% Date od recording
row = 1;
trial_whisker_path = cell(length(tss),4);

for ts = tss
    disp(ts.name + ": Looking for associated whisker data")
    trial_whisker_path{row,1} = ts.name;
    % find date of recording
    date_rec = ts.start_time;
    % output date of recording
    trial_whisker_path{row,2} = date_rec;
    % change date format (same as in whisker data)
    daterecSS = datestr(date_rec,'yyyymmdd_HH-MM-SS');
    idx = contains(whiskers_file_names,daterecSS);
    idx = find(idx,1);
    
    % Give threshold
    if isempty(idx)
        disp('No perfect match found. Giving threshold...')
        % threshold ± 30s
        threshold_s = sort((-59:59),"ComparisonMethod","abs");
        threshold_s = nonzeros(threshold_s);
        for i = 1:length(threshold_s)
            dr = date_rec + seconds(threshold_s(i));
            daterecSS = datestr(dr,'yyyymmdd_HH-MM-SS');
            idx = contains(whiskers_file_names,daterecSS);
            if any(idx)
                idx = find(idx,1);
                trial_whisker_path{row,3} = fullfile(whiskers_files(idx).folder,whiskers_files(idx).name);
                disp("Whisker data found with a threshold of " + threshold_s(i) + "s")
                break
            end
            trial_whisker_path{row,3} = nan;
        end
        
        % threshold ± 5 min
        if isnan(trial_whisker_path{row,3})
            disp('No whisker data found with ± 30s threshold')
            threshold_m = sort((-10:10),"ComparisonMethod","abs");
            threshold_m = nonzeros(threshold_m);
            for i = 1:length(threshold_m)
                dr = date_rec + minutes(threshold_m(i));
                daterecMM = datestr(dr,'yyyymmdd_HH-MM');
                idx = contains(whiskers_file_names,daterecMM);
                if any(idx)
                    idx = find(idx,1);
                    trial_whisker_path{row,3} = fullfile(whiskers_files(idx).folder,whiskers_files(idx).name);
                    disp("Whisker data found with a threshold of " + threshold_m(i) + "min")
                    break
                end            
                trial_whisker_path{row,3} = nan;
            end
            disp('No whisker data found with ± 10 min threshold')
        end
        
        % check if there are more than one whisker data overlapping in time (very unlikely)
    elseif length(idx) > 1
        warning("There was more than one whisker data overlapping in time with " + ts.name)
        trial_whisker_path{row,3} = [fullfile(whiskers_files(idx(1)).folder,whiskers_files(idx(1)).name),...
            fullfile(whiskers_files(idx(2)).folder,whiskers_files(idx(2)).name)];
    else
        disp("Perfect match! Whisker data found")
        trial_whisker_path{row,3} = fullfile(whiskers_files(idx).folder,whiskers_files(idx).name);
    end
    
    % Calculate difference between the start time of ts data vs. whisker data
    if ~isnan(trial_whisker_path{row,3})
        [~,n,~]=fileparts(trial_whisker_path{row,3});
        n = datetime(n,"InputFormat","yyyyMMdd_HH-mm-ss.SSS", "Format",'dd-MMM-uuuu HH:mm:ss.SSS');
        time_difference = duration((n - date_rec),'Format','hh:mm:ss.SSS');
        trial_whisker_path{row,4} = time_difference;
    else
        trial_whisker_path{row,4} = nan;
    end
     
    % Save whisker path in tseries metadata
    if ~isnan(trial_whisker_path{row,3})
        whisker_path = string(trial_whisker_path{row,3});
        ts.save_var('Whisker_path', whisker_path)
        disp('Whisker path saved')       
    end
      row = row + 1;
end   
    % Convert to table
    whisker_tab = cell2table(trial_whisker_path,'VariableNames',{'Tseries_name','Date_recording','Whisker_path','Time_difference'});
    idx = ~isnan(whisker_tab.Time_difference);
    whisker_tab_valid = whisker_tab(idx,:);
    
    % Check if the time difference is postitive (whiscker recording cannot
    % start before the TTL pulse!(unless PCs times are wrong))
    if any(whisker_tab_valid.Time_difference < 0)
        warning('Something is wrong with the time difference. Check it')
    end
    
end