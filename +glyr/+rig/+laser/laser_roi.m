function laser_roi (varargin)
if length(varargin) < 2
trials = varargin{1};   
else
trials = glyr.rig.get_rig(gdata,tss);
end
disp("Number of trials: " + numel(trials))
idx = ~trials.has_var('video_region_names');
trials_to_mark = trials(idx);
disp("Trials marked: " + sum(~idx) + ". Trials to mark: " + numel(trials_to_mark))
yucca.mod.camera_regions.configure(trials_to_mark);
end