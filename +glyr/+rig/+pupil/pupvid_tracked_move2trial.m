function pupvid_tracked_move2trial(trials,vids_path)
% move analyzed pupil video to trial folder
if nargin < 2, error('"Specify folder (E.g. "/Volumes/GlyR/pupil/noIVM)"'),end
import begonia.logging.backwrite
warning("If the same DLC mocel was use to track the pupil and video already exist" + ...
    " video will be overwritten")
% Get video paths
pp = dir(fullfile(vids_path,'*_labeled.mp4'));
if ~isempty(pp)
    pp = string(fullfile({pp.folder},{pp.name}))';
else
    error("Wrong Pupil tracked video folder")
end

% Move videos to trial folder
for i = 1:length(trials)
    backwrite(1,'Copying video files to trials:%d/%d', i,length(trials))
    vidp = dir([trials(i).path,'/*pupil_video.mp4']);
    pupil_path = fullfile(vidp.folder,vidp.name);
    if isfile(pupil_path)
        name = vidp.name;
        cname_idx = strfind(name,'.')-1;
        cname = name(1:cname_idx);
        pp_idx = contains(pp,cname);
        pupv_path = pp(pp_idx);
        copyfile(pupv_path,trials(i).path)
    else
        warning(trials(i).path + " does not have pupil")
    end
end
end