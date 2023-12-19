function move_pup2analysis(trials,analysis_path)
if nargin < 2, error('"Specify destination folder (E.g. "/Volumes/GlyR/pupil/noIVM)"'),end
for i = 1:length(trials)
    pp = dir(fullfile(trials(i).path,'*_pupil_video.mp4'));
    if ~isempty(pp)
        pp = fullfile(pp.folder,pp.name);
        copyfile(pp,analysis_path)
    else
        pupil_path = fullfile(trials(i).path,'pupil_video.mp4');
        if isfile(pupil_path)
            idx = strfind(pupil_path,'202');
            new_name = pupil_path(idx:end);
            new_name = replace(new_name,'/','_');
            new_path = fullfile(trials(i).path,new_name);
            movefile(pupil_path,new_path)
            copyfile(new_path,analysis_path)
        else
            continue
        end
    end
end
end