function make_pupil_video(trial)
% make videos from cropped area for analysis
import begonia.logging.log
log(1, "Make pupil video for analysis from " + trial.path)
pupil_path = fullfile(trial.path,'pupil_data');
pupil_frames = dir(fullfile(pupil_path,'*.png'));
pupil_frames = string(fullfile(pupil_path,{pupil_frames.name}))';

frames = arrayfun(@imread,pupil_frames,'UniformOutput',false);
crop_area = trial.load_var('pupil_crop');
frames = cellfun(@(s) imcrop(s,crop_area),frames,'UniformOutput',false);
frames = cellfun(@imadjust,frames,'UniformOutput',false);

frames = cat(3,frames{:});

vid_path = fullfile(trial.path,'pupil_video.mp4');

vid = VideoWriter(vid_path,'MPEG-4');
vid.open();
for i = 1:size(frames,3)
    writeVideo(vid,frames(:,:,i));
end
vid.close();
end