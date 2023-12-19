function wheel_to_mtab(gdata,tss)

trials = glyr.rig.get_rig(gdata,tss);

for trial = trials
    if trial.has_var('wheel_trim')
        wheel_trim = trial.load_var('wheel_trim');
    else
        warning(trial.path + " has no wheel trim")
        continue
    end
    dt = wheel_trim.TimeInfo.End / wheel_trim.TimeInfo.Length;
    ts = yucca.trial.correlate_stacks_alt(tss,trial);
    trace = wheel_trim.Data * -1;
    data_id = "wheel-" + ts.name;
    group_id = string(ts.name);
    category = "wheel";
    % Update mtab 
    gdata.mtab.update(trace,data_id, group_id, category,"", "d/s", dt);    
end
disp('mtab updated with wheel data')
gdata.mtab.save();
disp('mtab saved')
end
