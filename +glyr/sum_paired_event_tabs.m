% Grab the excel sheets that contains the event rate of the different roi
% types in the different behaviour states paired and sum up the info.
% Ouptus aan table saved in the same directory. The table basically
% contains the amount of rois active in each experimental state and  if the
% by how much the event rate change (baseline v. stimulation)
dirs = dir('/Volumes/GlyR/GlyR project/Plots/Activity_summary/Paired/GlyR/noIVM/**/*.xls');
paths = fullfile({dirs.folder},{dirs.name});
paths = string(paths);
for pp = paths  
    p1 = readtable(pp);
    total = height(p1);
    
    p1.evs_base = round(p1.evs_base,1);
    p1.evs_stim = round(p1.evs_stim,1);
    
    active_stim = sum(p1.evs_stim > 0);
    active_base = sum(p1.evs_base > 0);
    
    % differences
    same = sum(p1.evs_base == p1.evs_stim)/total;
    more = sum(p1.evs_base < p1.evs_stim)/total;
    less = sum(p1.evs_base > p1.evs_stim)/total;
    
    % Number of active rois
    active_rois =  sum(p1.evs_base > 0 | p1.evs_stim > 0 );
    
    p = p1(p1.evs_base > 0 | p1.evs_stim > 0,:);
    act_same = sum(p.evs_base == p.evs_stim)/active_rois;
    act_more = sum(p.evs_base < p.evs_stim)/active_rois;
    act_less = sum(p.evs_base > p.evs_stim)/active_rois;
    
    % make table
    rois = [total;active_rois];
    base = [active_base; active_base];
    stim = [active_stim; active_stim];
    sam = [same;act_same];
    le = [less;act_less];
    mor = [more;act_more];
    
    col_names = {'Total','Baseline','Stimulation','Same','Less','More'};
    row_names = {'All','Active'};
    
    tt = table(rois,base,stim,sam,le,mor,'RowNames',row_names,'VariableNames',col_names);
    
    % save as an excel sheet
    folder = fileparts(pp);
    if contains(folder,"Paired")
        c = "Paired";
    else
        c = "Unpaired";
    end
    filename = c + "_" + unique(p1.behav) + "_" + unique(p1.roi_type);
    filename = fullfile(folder,filename);
    begonia.path.make_dirs(filename);
    writetable(tt,filename,'FileType','spreadsheet')
end