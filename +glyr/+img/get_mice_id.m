function mice_id = get_mice_id(path)
% Mice names are in the folders' name inside "img" folder
% mice_id = list w/ mice names
if nargin < 1
    path = '/Volumes/GlyR/GlyR project/img';
    if ~isfolder(path)
        path = uigetdir;
    end
end
dirs = dir(path);
m_n = {dirs.name};
mice_id = m_n( ~contains(m_n,"."));
mice_id = string(mice_id);
end