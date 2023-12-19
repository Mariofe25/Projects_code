function whisklog_to_mtab(gdata,tss)

% It takes the 
trials = glyr.rig.get_rig(gdata,tss);

for trial = trials
    if trial.has_var('whisker_log')
        whisk_log =  trial.load_var('whisker_log');
    else
        warning(trial.path + " has no whisker log")
        continue
    end
    ts = yucca.trial.correlate_stacks_alt(tss,trial);
    trace = whisk_log.wall;
    dt = 1/30;
    data_id = "whiskerlog-" + ts.name;
    group_id = string(ts.name);
    category = "whisker";
    
    gdata.mtab.update(trace,data_id, group_id, category,"", "s", dt);
end

disp('mtab updated with whisker logs')
gdata.mtab.save();
disp('mtab saved')
end




