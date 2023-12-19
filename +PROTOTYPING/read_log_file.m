%% Find log file of wheel data
function logfile = read_log_file (gdata,tss,valid_tss_names)

row = 1;

tss_names = string({tss.name});
tss_idx = ismember(tss_names,valid_tss_names);
tss = tss(tss_idx);

logfile = cell(length(tss),1);

for ts = tss
    
    disp("Extracting log file from " + ts.name)
    tsi = gdata.dcat.get_info(ts.dl_unique_id);
    rig = tsi.overlaping_in_time({tsi.overlaping_in_time.type} == "Recording rig output");
    rig = gdata.dcat.get_data(rig);
    logfile{row} = rig.Log;
    row = row + 1;
    
end

end
