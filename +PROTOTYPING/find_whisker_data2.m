%% this function creates a table with the name of the tseries(1), Date of recording(2), Whisker data path(3), Trial-Whisker data Time difference(4)
function [trial_whisker_path_valid,trial_whisker_path] = find_whisker_data2(gdata,tss)

if nargin <= 1
    error('Input should look like this --> find_whisker_data (gdata,tss)')
end

% folder with whisker data
whisker_folder = '/Volumes/My Book Duo';
if ~isfolder(whisker_folder)
    fprintf('Whisker folder does not exist or it has been moved to other location \nLook for it\n')
    whisker_folder = uigetdir;
end

% list whisker data paths
whiskers_files = dir(whisker_folder);
whiskers_file_names = {whiskers_files.name}';

% find trials base on tseries name
row = 1;
trial_whisker_path = cell(length(tss),4);
for ts = tss
    disp("Looking for Whisker data of " + ts.name)
    trial_whisker_path{row,1} = ts.name;
    tsi = gdata.dcat.get_info(ts.dl_unique_id);
    rig = tsi.overlaping_in_time({tsi.overlaping_in_time.type} == "Recording rig output");
    if ~isempty(rig)
        rig = gdata.dcat.get_data(rig);
    else
        disp("No rig data found")
        trial_whisker_path{row,4} = nan;
        row = row + 1;
        continue;
    end
    
    % find date of recording
    date_rec = rig.DateRecorded;
    % find time of recording (P1 time)
    logf = rig.Log;
    time_P1 = logf.Time(strcmp(logf.Message, 'P1'));
    % update date of recording with P1 time
    date_rec.Minute = time_P1.Minute;
    date_rec.Second = time_P1.Second;
    % output date of recording
    trial_whisker_path{row,2} = date_rec;
    % find the whisker data comparing datetime
    daterecSS = datestr(date_rec,'yyyymmdd_HH-MM-SS');
    %%idx = strfind(whiskers_file_names,daterec);
    %%idx = find(~cellfun(@isempty,idx));
    idx = contains(whiskers_file_names,daterecSS);
    idx = find(idx,1);
    
    if isempty(idx)
        warning('No whisker data found for this trial. It could be that the time between the two PCs is not well synchronized. Giving threshold')
        % threshold ± 30s
        threshold_s = sort((-30:30),"ComparisonMethod","abs");
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
            trial_whisker_path{row,3} = "not found";
            
        end
        
        % threshold ± 5 min
        if trial_whisker_path{row,3} == "not found"
            
            threshold_m = sort((-5:5),"ComparisonMethod","abs");
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
                trial_whisker_path{row,3} = "not found";
            end
            
        end
        
        % check if there are more than one whisker data overlapping in time (very unlikely)
    elseif length(idx) > 1
        
        warning("There was more than one whisker data overlapping in time with " + ts.name)
        
        trial_whisker_path{row,3} = [fullfile(whiskers_files(idx(1)).folder,whiskers_files(idx(1)).name),...
            fullfile(whiskers_files(idx(2)).folder,whiskers_files(idx(2)).name)];
        
    else
        
        disp("Whisker data found!")
        
        trial_whisker_path{row,3} = fullfile(whiskers_files(idx).folder,whiskers_files(idx).name);
        
    end
    
    % Calculate difference between the start time of rig data vs. whisker
    % data
    if ~isequal(trial_whisker_path{row,3},"not found")
        [~,n,~]=fileparts(trial_whisker_path{row,3});
        n = datetime(n,"InputFormat","yyyyMMdd_HH-mm-ss.SSS", "Format",'dd-MMM-uuuu HH:mm:ss.SSS');
        time_difference = duration((n - date_rec),'Format','hh:mm:ss.SSS');
        trial_whisker_path{row,4} = time_difference;
        row = row + 1;
    else
        trial_whisker_path{row,4} = nan;
        row = row + 1;
    end
    
end

% Convert to table
trial_whisker_path = cell2table(trial_whisker_path,'VariableNames',{'Tseries_name','Date_recording','Whisker_path','Time_difference'});
idx = ~isnan(trial_whisker_path.Time_difference);
trial_whisker_path_valid = trial_whisker_path(idx,:);
% Check if the time difference is postitive (whiscker recording cannot start before the TTL pulse!(unless PCs times are wrong)
if any(trial_whisker_path.Time_difference < 0)
    warning('Something is wrong with the time difference. Check the threshold')
end

end
