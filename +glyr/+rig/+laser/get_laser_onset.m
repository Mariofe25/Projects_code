% Find when the laser is on to synchronyze imaging with rig and whisker data
function laser = get_laser_onset(varargin)
%% Read laser roi
if numel(varargin) > 1
    gdata = varargin{1};
    tss = varargin{2};
    [trials,tss_with_trials] = glyr.rig.get_rig(gdata,tss);
    tss_paths = {tss_with_trials.path};
else
    trials = varargin{1};
end
disp('Extracting laser trace. This can take a while for new data...')
laser = cell(length(trials),4);
for i = 1:numel(trials)
    if ~trials(i).has_var('laser_data')
        if trials(i).has_var('video_region_names')
            try
                disp("Reading laser roi data from " + trials(i).path + "...")
                videoroi_data = yucca.mod.camera_regions.read(trials(i));
                laser_data = videoroi_data.laser;
                if nargout == 1
                    if numel(varargin) > 1
                        laser{i,1} = tss_paths(i);
                    else
                        laser{i,1} = trials(i).associated_stacks.path;
                    end
                    laser{i,2} = trials(i).path;
                    laser{i,3} = laser_data;
                end
                trials(i).save_var('laser_data',laser_data)
                disp('Laser data saved')
            catch err
                disp(err.message)
                if nargout == 1
                    if numel(varargin) > 1
                        laser{i,1} = tss_paths(i);
                    else
                        laser{i,1} = trials(i).associated_stacks.path;
                    end
                    laser{i,2} = trials(i).path;
                end
                continue
            end
        else
            warning(trials(i).path + " does not have laser roi data. Skipping")
            continue
        end
    else
        disp(trials(i).path + " already has laser roi data available")
        if nargout == 1
            if numel(varargin) > 1
                laser{i,1} = tss_paths(i);
            else
                laser{i,1} = trials(i).associated_stacks.path;
            end
            laser{i,2} = trials(i).path;
            laser{i,3} = trials(i).load_var('laser_data');
        end
    end
end

%% Find when the laser turns on
for i = 1: length(trials)
    %look for the laser onset in the first 2s of the recording
    if  trials(i).has_var('laser_data')
        d = trials(i).load_var('laser_data');
        idx = d.Time <= 2;
        [~,loc] =  max(d.Data(idx));
        laser_onset = d.Time(loc);
        trials(i).save_var('laser_onset',laser_onset)
        disp('Laser onset saved')
        if nargout == 1
            laser{i,4} = laser_onset;
        end
    elseif isempty(laser{i,3})
        continue
    else
        disp(trials(i).path + " already has laser onset data.")
        if nargout == 1
            laser{i,4} = trials(i).load_var('laser_onset');
        end
    end
end
if nargout == 1
    laser = cell2table(laser,'VariableNames',{'Tseries_path','Trial_path','Laser_Data','Laser_onset'});
end
disp('Done')
end

