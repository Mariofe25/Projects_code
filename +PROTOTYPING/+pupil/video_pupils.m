function video_pupils(trial,output_path)

% Modify from knut's code
% It creates a video with all the frames marked with the pupil diamter
% measured.
%
% INPUTS: 
%            - trial: yuccca.trial
%            - output_path: path where video is saved
%
% OUTPUT:  Video can be found in the output_path
%
%--------------------------------------------------------------------------

import glyr.pupil.*;


if nargin < 2
  output_path = fullfile(trial.path,'pups_diameters');  
end

pupil_trial = yucca.mod.ptracker.PupilVideoReader(trial.path);
pupil_images = pupil_trial.png_files;
config_pupil = load_var(trial,'config_pupil');

% run in parallel to speed up the process
nframes = length(pupil_images);
parfor i = 1:nframes
    if mod(i, 100) == 0
        disp(i + " frames generated");
    end
    [~,frame] = analyse_pupil([],pupil_images{i},config_pupil);
    frame = rgb2gray(frame);
    video_frames(:,:,i) = frame;
end

% write the video:
vwriter = VideoWriter(output_path, 'MPEG-4');
vwriter.FrameRate = 45;
open(vwriter);
for i = 1:size(video_frames, 3)
    if mod(i, 100) == 0
        disp(i + " frames written");
    end
    vwriter.writeVideo(video_frames(:,:,i));
end
disp("Video saved in " + output_path)
close(vwriter);
end
