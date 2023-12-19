function is_running(mtab,data)

idx = cellfun(@isempty,data);
data(idx) = [];


for i = 1:length(data)
    
    wheel = data{i}.trace(data{i}.category == "wheel");
    wheel_trace = wheel{:};
    
    % smooth, find baseline and classify:
    wheel_trace = movsum(wheel_trace, 20);
    run = wheel_trace > 20;
    trace = run;
    
    dt = unique(data{i}.delta_time);
    group_id = unique(data{i}.group_id);
    data_id = "bh_locomomtion-" + string(group_id);
    category = "binarized_running";
    
    mtab.update(trace,data_id, group_id, category,"", "binarize", dt);
    mtab.save();
end
end