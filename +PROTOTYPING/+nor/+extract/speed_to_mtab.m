function speed_to_mtab(tss, nordata)

for ts = tss
    disp(ts.name)
    tsi = nordata.dcat.get_info(ts.dl_unique_id);
    rig = tsi.overlaping_in_time({tsi.overlaping_in_time.type} == "Recording rig output");
    if length(rig) >= 2
        warning(ts.name + " has more than one trial associated. Last trial was selected. CHECK TIME OF RECORDING")
        rig = nordata.dcat.get_data(rig(end));
    else
         rig = nordata.dcat.get_data(rig)
    end
    
    wheel = yucca.mod.wheel.read(rig);
    
    dt = wheel.DeltaAngle.TimeInfo.End / wheel.DeltaAngle.TimeInfo.Length;
    
    trace = wheel.DeltaAngle.Data * -1;
    
    data_id = "wheel-" + ts.name;
    group_id = string(ts.name);
    category = "wheel";
    
    %       tag = "; ts_date=" + string(ts.start_time) + ";mouse =" + ;
    nordata.mtab.update(trace,data_id, group_id, category,"", "d/s", dt);
end

nordata.mtab.save();
end


