function airpuff_to_mtab(tss,gdata)

for ts = tss
    tsi = gdata.dcat.get_info(ts.dl_unique_id);
    rig = tsi.overlaping_in_time({tsi.overlaping_in_time.type} == "Recording rig output");
    disp("Extracting airpuff time from " + ts.name)
    if isempty(rig)
        warning("Skipping " + ts.name + ", no Rig data");
        continue;
    end
    
    rig = gdata.dcat.get_data(rig);
    logfile = rig.Log;
    airpuff = airpuff_time (logfile);
    
    trace = airpuff;
    data_id = "airpuff-" + ts.name;
    group_id = string(ts.name);
    category = "airpuff";
    dt = 1;
    gdata.mtab.update(trace,data_id, group_id, category,"", "s",dt);
    
end

gdata.mtab.save();
disp("Megatebale updated with airpuff info")

end


% find the start and end time of the airpuff 
function airpuff = airpuff_time (logfile)

    air_idx = find(ismember(logfile.Code,'AIRPUFF'));
    
    st_rec_idx = find(ismember(logfile.Message,'P1'));
    
    start = seconds(logfile.Time(air_idx(1)) - logfile.Time(st_rec_idx));
    
    stop = seconds(logfile.Time(air_idx(end))- logfile.Time (st_rec_idx));
    
    airpuff = [start;stop];
    
end



