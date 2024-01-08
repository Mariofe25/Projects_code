function tss = load_dataset(dataset)
if nargin < 1, dataset = []; end

if dataset == "noIVM"
    dataset_path = "GlyR project/Analysis/GlyR_noIVM_selected.mat";
elseif dataset == "IVM"
    dataset_path = "GlyR project/Analysis/GlyR_IVM_selected.mat";
elseif dataset == "postIVM"
    dataset_path = "GlyR project/Analysis/GlyR_postIVM_selected.mat";
elseif dataset == "no_GlyR_noIVM"
    dataset_path = "GlyR project/Analysis/non_GlyR_noIVM_selected.mat";
elseif dataset == "no_GlyR_IVM"
    dataset_path = "GlyR project/Analysis/non_GlyR_IVM.mat";
elseif dataset == "no_GlyR_postIVM"
    dataset_path = "GlyR project/Analysis/non_GlyR_postIVM.mat";
else
    error("Select dataset: noIVM,IVM,postIVM,no_GlyR_noIVM,no_GlyR_IVM or" + ...
        " no_GlyR_postIVM")
end

os_path = "/Volumes/GlyR/";

if ismac
    os = "Mac";
    HDs = dir('/Volumes');
    GlyRon =  any(ismember(string({HDs.name}),'GlyR'));
    root_path = "/Volumes/GlyR/";
    old_root = "^[A-Z]:/";
else
    os = "Windows";
    HDs = glyr.util.listPhysicalDrives();
    disks = ismember([HDs.VolumeName],'GlyR');
    GlyRon =  any(disks);
    root_path = HDs.DeviceID(disks) + ":/";
    old_root = "/Volumes/GlyR/";
end

dlocs = load(root_path + dataset_path);
dlocs = dlocs.dlocs;
paths = string({dlocs.path});
mac_root = all(contains(paths,os_path));


if ismac && mac_root || ispc && ~mac_root
    disp("Metadata already in correct " + os + " format.Loading...")
    tss = dlocs;

    for i = 1:length(tss)
        % If present, change also associated trial path in metadata
        if tss(i).has_var('associated_trial')
            trial_path = tss(i).load_var('associated_trial');
            if any(strfind(trial_path,"\"))
                trial_path =  replace(trial_path,"\","/");
            end
            newtp =  regexprep(trial_path,old_root,root_path);
            tss(i).save_var('associated_trial',newtp);
        end
    end

else
    disp("Metadata need to be updated to be read by " + os + " OS")
    % grab paths and change name depending on OS
    newpath = regexprep(paths,old_root,root_path);
    for i = 1:length(dlocs)
        tss(i) = begonia.scantype.find_scans(newpath(i));
        % If present, change also associated trial path in metadata
        if tss(i).has_var('associated_trial')
            trial_path = tss(i).load_var('associated_trial');
            if any(strfind(trial_path,"\"))
                trial_path =  replace(trial_path,"\","/");
            end
            newtp =  regexprep(trial_path,old_root,root_path);
            tss(i).save_var('associated_trial',newtp);
        end
    end
end

if ~isrow(tss)
    tss = tss';
end
end