function [pupil_data,pupil_measured] = analyse_pupil(trial,pupil_image,config_pupil)
%
% This function takes the otputs from configure_pupil function to analyse 
% frames individually.
%
% INPUTS:  
%            - trial: yucca.trial
%            - pupil_image: random pupilimage from the recording (input as
%            and integer)
%            - config_pupil: struct with rec,eye_area,artifacts masks
%                 
%   
% OUTPUTS:  
%            - pupil_data: struct with information about the pupil detected
%           (Area, diameter,center)
%            - pupil_measured: image with the pupil marked and showing
%            diameter size in px. Can later be use as a frame in
%            vide_pupils funciton
%--------------------------------------------------------------------------
if nargin < 2
  pupil_image = 5;
end

if nargin < 3
    if ~trial.has_var('config_pupil')
        error(trial.path + " does not have the pupil configurated.")
    else
        config_pupil = trial.load_var('config_pupil');
    end
end

% get config
rec = config_pupil.rec;
eye_area = config_pupil.eye_area;
artifacts = config_pupil.artifacts;

% read,crop and adjust contrast pupil image

if  isscalar(pupil_image) && isnumeric(pupil_image)
    pupil_trial = yucca.mod.ptracker.PupilVideoReader(trial.path);
    pupil_path = pupil_trial.png_files{pupil_image};
    pupil = imread(pupil_path);
else
    if ischar(pupil_image)
        pupil = imread(pupil_image);
    else
        pupil = pupil_image;
    end
end

pupil = imcrop(pupil,rec);
pupil = imadjust(pupil);

% read,crop and adjust  contrast pupil image

% filter image(denoise image while not affecting much the edges)
%%%pupil = imguidedfilter(pupil);

% remove artifacts (interpolation)
if ~isempty(artifacts)
    pup = regionfill(pupil,artifacts);
else
    pup = pupil;
end

% apply eye_area mask
pup= double(pup).* eye_area;

% Pupil threshold
tresh = multithresh(pup,3); % 2 or 3
bw_pup = imquantize(pup,tresh);
bw_pup = bw_pup == 4; % 3 or 4

% Process pupil size
bw_pup = imerode(bw_pup,strel('disk',5));

% Find regions
regions = regionprops(bw_pup,'Area','BoundingBox','Centroid','Eccentricity',...
    'EquivDiameter','Circularity');

% Filter regions by area and eccentricity
pupil_idx = find([regions.Area] > 1000 & [regions.Eccentricity] < 0.5);
pupil_region = regions(pupil_idx);

if isempty(pupil_region)
    pupil_data = []; %blink
    pupil_measured = insertObjectAnnotation(pupil,'rectangle',...
        [100,100,200,200],'No Pupil/Blink','TextColor','white',...
        'Color','black','LineWidth',2);
else
    pupil_data =  rmfield(pupil_region,{'Circularity','Eccentricity'});
    %     pupil_measured = insertObjectAnnotation(pupil,'rectangle',...
    %         pupil_data.BoundingBox,"Diameter:  " + ...
    %         round(pupil_data.EquivDiameter) + " px");
    
    pupil_measured = insertObjectAnnotation(pupil,'circle',...
        [pupil_data.Centroid,pupil_data.EquivDiameter/2],"Diameter:  " + ...
        round(pupil_data.EquivDiameter) + " px",'TextColor','white',...
        'Color','black','LineWidth',2);
end

end




