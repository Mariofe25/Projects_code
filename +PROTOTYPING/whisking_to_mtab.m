function whisking_to_mtab(gdata,tss)

trials = glyr.rig.get_rig(gdata,tss);

for trial = trials
    if trial.has_var('whisking_trim')
        whisking_trim =  trial.load_var('whisking_trim');
    else
        warning(trial.path + " has no whiskisng trimmed var")
        continue
    end
    ts = yucca.trial.correlate_stacks_alt(tss,trial);
    trace = whisking_trim.Data;
    % Usually it is 30fps, but not always.
    dt = whisking_trim.TimeInfo.End/whisking_trim.TimeInfo.Length;
    data_id = "whisking-" + ts.name;
    group_id = string(ts.name);
    category = "whisker";
    
    gdata.mtab.update(trace,data_id, group_id, category,"", "px_diff", dt);
    
end

disp('mtab updated with whisking')
gdata.mtab.save();
disp('mtab saved')
end

