% Find when the laser is on to synchronyze imaging with rig and
% whisker data

%% List trials
% tab = readtable('/Volumes/GlyR/trials.xlsx');
row = 1;
laser = cell(length(tss),4);
for ts = tss
    disp("Looking for Whisker data of " + ts.name)
    laser{row,1} = ts.name;
    tsi = gdata.dcat.get_info(ts.dl_unique_id);
    rig = tsi.overlaping_in_time({tsi.overlaping_in_time.type} == "Recording rig output");
    trials(row,1) = gdata.dcat.get_data(rig);
    row = row + 1; 
end

% for i = 1:size(tab,1)
%     
%     trials(i)= yucca.trial.Trial(tab.x_Volumes_GlyR_GlyRProject_AABe_2020_01_14_132445_trial_001_Mou{i});
%         
% end
%% Make laser video ROI // (it would be possible to use a mask to automatize it --> (take one trial and take its mask to the rest) do it later)
yucca.mod.camera_regions.configure(trials)

%% get laser trace
disp('Getting laser trace of each trial. This can take a while')
row = 1;
laser = cell(length(trials),3);
for trial = trials
    laser{row,2} = trial.path;
    if ~trial.has_var('video_region_names')
        warning(trial.name + " does not have laser roi")
        row = row + 1;
        continue
    else
        videoroi_data = yucca.mod.camera_regions.read(trial);
        laser_data = videoroi_data.laser;
        laser{row,3} = videoroi_data.laser;
    end
    row = row + 1;
end

%% Find when the laser turns on
for i = 1: length(laser)
%look for the laser onset in the first 2s of the recording
idx = laser{i,2}.Time <= 2;
[~,loc] =  max(laser{i,2}.Data(idx)); 
laser_onset = laser{i,2}.Time(loc);
laser{i,4} = laser_onset;
end

laser = cell2table(laser,'VariableNames',{'Tseries_name','Whisker_path','Laser Data','Laser onset'});

