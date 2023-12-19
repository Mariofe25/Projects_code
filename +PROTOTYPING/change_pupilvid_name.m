for i = 1:length(trials)
    pp = dir(fullfile(trials(i).path,'*_pupil_video.mp4'));
    pp = fullfile(pp.folder,pp.name);
    if isfile(pp)
        copyfile(pp,'/Volumes/GlyR/pupil/noIVM')
    else
        pupil_path = fullfile(trials(i).path,'pupil_video.mp4');
        if isfile(pupil_path)
            idx = strfind(pupil_path,'202');
            new_name = pupil_path(idx:end);
            new_name = replace(new_name,'/','_');
            new_path = fullfile(trials(i).path,new_name);
            movefile(pupil_path,new_path)
            copyfile(new_path,'/Volumes/GlyR/pupil/noIVM')
        else
            continue
        end
    end
end