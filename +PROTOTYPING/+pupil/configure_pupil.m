function config_pupil = configure_pupil(trial,pupil_image)

% Take one frame of the pupil recording to create the area of the image to
% be anlayse. After creating the masks for the eye and the artifacs it is
% required to manually save the mask(s) generated.
%
% INPUT:        - trial: yucca.trial
%               - random_pupil: integer (1:length(frames recording)
%
% OUTPUT:       - config_pupil: struct with rec,eye_area,artifacts masks
%               *artiffacts = light aberrations*

%--------------------------------------------------------------------------

% read image (it is desirable that the pupil is contracted to better see the
% artifacts)
import glyr.pupil.*

% check if a configuration already exist

if trial.has_var('config_pupil')
    promptMessage = 'Do you want to continue? If yes, current config will be replaced ';
    titleBarCaption = 'Config_pupil already exist';
    button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'No');
    if strcmpi(button, 'No')
        disp('Pupil configuration aborted')
        return
    end
end

if nargin < 2
    pupil_image = 5;
end

if isempty(yucca.mod.ptracker.PupilVideoReader(trial.path))
    error(trial.path + " does not have a pupil recording ")
end

pupil_trial = yucca.mod.ptracker.PupilVideoReader(trial.path);
pupil_path = pupil_trial.png_files{pupil_image};
pupil_to_config = imread(pupil_path);

% crop eye region
disp('Step 1.Select eye area')
figure
[pupil_to_config,rec] = imcrop(pupil_to_config);
disp('Eye area slected')
close

% make eye mask
disp('Step 2. Select mask for sclera')
figure
eye = CROIEditor(pupil_to_config);

while isempty(eye.roi)
    pause(1)
end
eye_area = eye.roi;
eye.delete
disp('Sclera mask created')

% eye_area = addlistener(eye,'MaskDefined',@your_roi_defined_callback);
%     function your_roi_defined_callback(h,e)
%         [mask, labels, n] = eye.roi;
%     end
% eye_area = eye_area.Source{1}.roi
% waitfor(eye)

% make artifacts mask
promptMessage = 'Would you like to create a mask for artifacts(s) ';
titleBarCaption = 'Artifacts mask';
button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'No');
if strcmpi(button, 'Yes')
    artefacts = CROIEditor(pupil_to_config);
    while isempty(artefacts.roi)
        pause(1)
    end
    artifacts = artefacts.roi;
    artefacts.delete
    disp('Artifacts mask created')
else
    artifacts = [];
    disp('No mask for artifacts created')
end

config_pupil = struct('rec',rec,'eye_area',eye_area,'artifacts',artifacts);

save_var(trial,config_pupil)
disp("pupil configuration has been saved in " + trial.dloc_metadata_dir)
end
