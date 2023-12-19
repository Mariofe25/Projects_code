function move_aligns2(path,new_path,same_path)
% By default aligned tseries remain in their own folder. If same_path is false, 
% all aligned tseries are moved to the Aligned folder in the parent folder  
% unless it is specified where to move them.
if nargin < 3
    same_path = false;
end

if nargin < 2
    same_path = true;
    new_path = path;
end

if ~isfolder(path)
    error("folder does not exist")
end
% 
disp('Scanning aligned tseries...')
% the scan time depends on the number of files/folders(subfolders)
dirs = dir(path + "/**/*_aligned");
% avoid creating nested Aligned folders
dirs = dirs(~contains({dirs.folder},'Aligned'));
if isempty(dirs)
    disp('No aligned tseries to be moved')
else
    disp(length(dirs) + " new aligned tseries found")
    disp("Moving aligned tseries...")   
    for i = 1:numel(dirs)
        sub_folder = dirs(i).folder;
        file = dirs(i).name;
        if same_path
            aligned_folder = sub_folder  + "/Aligned";
        else
            if ~isequal(new_path,path)
                aligned_folder = string(new_path) + "/Aligned";
            else
                aligned_folder = string(path) + "/Aligned";
            end
        end
        if  isfolder(aligned_folder)
            %fprintf('Aligned folder already exist.\nMoving aligned tseries there...\n ')
        else
            mkdir(aligned_folder)
            %disp("Aligned folder created in " + sub_folder)
        end
        movefile(fullfile(sub_folder,file),aligned_folder)
    end
end
disp('Done')
end




