function [pups_data] = analyse_pups(trial)

% It analyse all frames of the recording using the analyase_pupil
% function.
%
% INPUTS:
%            - trial: yucca.trial
% OUPUT:            
%            - pupil_data: table with information about the pupil detected
%           (Time, Area, diameter,center, pupil_boundaries)
%
%--------------------------------------------------------------------------

import glyr.pupil.*;

% get pupil images
pupil_trial = yucca.mod.ptracker.PupilVideoReader(trial.path);
pupil_images = pupil_trial.png_files;

% get pupil config
config_pupil = load_var(trial,'config_pupil');

% get time of the frames
pupil_time = pupil_trial.frame_time';

% run in parallel to speed up the process
nimages = length(pupil_images);
parfor i = 1:nimages
    if mod(i, 100) == 0
        disp(i + " images analysed");
    end
    
    [pupil_data,~] = analyse_pupil([],pupil_images{i},config_pupil);
    
    if ~isempty(pupil_data)       
        pupil_boundaries(i,:) = {pupil_data.BoundingBox}; %(x,y,height,width)
        diameter(i,:) = pupil_data.EquivDiameter;
        area(i,:) = pupil_data.Area;
        center(i,:) = {pupil_data.Centroid};       
    else
        pupil_boundaries(i,:) = {nan};
        diameter(i,:) = nan;
        area(i,:) = nan;
        center(i,:) = {nan};
    end
    
end

pups_data = table(pupil_time,diameter,pupil_boundaries,area,center);

trial.save_var(pups_data)
disp("pupils_data saved in " + trial.dloc_metadata_dir)

end