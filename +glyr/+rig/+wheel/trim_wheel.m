% Trim the wheel data at the laser onset
function [wheel_trim,wheel] = trim_wheel(trials)
%% Load laser onset
laser_onset = zeros(1,numel(trials));
for i = 1:numel(trials)
    if trials(i).has_var('laser_onset')
        disp("Getting laser onset" + " from " + trials(i).path)
        laser_onset(i) = trials(i).load_var('laser_onset');
    else
        laser_onset(i) = nan;
        continue
    end
end
laser_onset = laser_onset';

%% Trim wheel data
wheel = cell(1,length(trials));
wheel_trim = cell(1,length(trials));
disp('Trimming wheel data')
for i = 1:numel(laser_onset)
    wheel{i} = yucca.mod.wheel.read(trials(i));
    % Get wheel data indices lower than laser onset
    if ~isnan(laser_onset(i))
        idx_trim = find(wheel{i}.Time < laser_onset(i));
    else
        warning(trials(i).path + " does not have laser onset")
        continue
    end
    % Trim  entire wheel tscollection
    wheel_trim{i} = delsamplefromcollection(wheel{i},'index', idx_trim);
    % Correct the time shift
    dt = wheel{i}.Time(2) - wheel{i}.Time(1);
    wheel_trim{i}.Time = wheel_trim{i}.Time - numel(idx_trim) * dt;
    if wheel_trim{i}.TimeInfo.Start ~= 0
        wheel_trim{i}.Time = wheel_trim{i}.Time -  wheel_trim{i}.Time(1);
    end
    
    if ~trials(i).has_var('wheel_trim')
        trials(i).save_var('wheel_trim',wheel_trim{i}.DeltaAngle)
        disp("Wheel_trim saved")
    elseif trials(i).dl_changelog('laser_onset') > trials(i).dl_changelog('wheel_trim')
         trials(i).save_var('wheel_trim',wheel_trim{i}.DeltaAngle)
         disp("Wheel_trim updated")
    else
        disp(trials(i).path + " already has wheel data trimmed")
    end
end

end