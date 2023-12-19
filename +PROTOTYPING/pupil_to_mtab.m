function pupil_to_mtab(gdata,tss)

trials = glyr.rig.get_rig(gdata,tss);

for trial = trials
    if trial.has_var('pupil_trim')
        pup_data =  trial.load_var('pupil_trim');
    else
        warning(trial.path + " has no pupil trimmed.Skipping")
        continue
    end
    ts = yucca.trial.correlate_stacks_alt(tss,trial);
    pup_data.timepoint = seconds(pup_data.timepoint);
    pup_data = table2timetable(pup_data);
    % Resample to 30fps
    pup_data = retime(pup_data,"regular","nearest","TimeStep",seconds(1/30));
    pups_diameter = pup_data.diameter_px;
    % smooth trace
    pups_diameter = sgolayfilt(pups_diameter,3,21);
    trace = pups_diameter;
    dt = 1/30;
    data_id = "pupil-" + ts.name;
    group_id = string(ts.name);
    category = "pupil";
    
    gdata.mtab.update(trace,data_id, group_id, category,"", "d_px", dt);
end
disp('mtab updated with pupil data')
gdata.mtab.save();
disp('mtab saved')
end

