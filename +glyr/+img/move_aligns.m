% move aligned TSeries files to a new folder (**/Aligned)
function move_aligns(path,same_path)
if nargin < 2
    same_path = true;
end
if ~isfolder(path)
    error("folder does not exist")
end
dirs = dir(path);
dirs = dirs(~ismember({dirs.name},{'.','..'}));

if any(contains({dirs.name},'TSeries'))
    move_it(path,same_path)
else
    folders = fullfile({dirs.folder},{dirs.name});
    folders = folders(~ismember(folders,{'.','..'}));
    for i = 1:numel(folders)
        move_it(folders{i},same_path)
    end
end
disp('Done')
end

function move_it(folder,same_path)
sub_folder = folder;
files = dir([folder,'/*_aligned']);
if same_path
    aligned_folder = sub_folder  + "/Aligned";
else
    aligned_folder = string(path) + "/Aligned";
end
    if isempty(files)
        disp("No aligned tseries found in " + folder)
    else
        nf = length(files);
        disp(nf + " aligned tseries found in " + sub_folder)
        if  isfolder(aligned_folder)
            fprintf('Aligned folder already exist.\nMoving aligned tseries there...\n ')
        else
            mkdir(aligned_folder)
            disp("Aligned folder created in " + sub_folder)
            disp("Moving aligned tseries...")
        end
        for k = 1:numel(files)
            movefile(fullfile(sub_folder,files(k).name),aligned_folder)
        end
        disp("Aligned tseries moved to " + aligned_folder)
    end       
end

