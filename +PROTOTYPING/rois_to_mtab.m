function  rois_to_mtab(gdata,tss,mouse_id,states)

if nargin < 4
    states = {'IVM','Atr','Pre','Post','Praz','Control'};
end

if nargin < 3 || isempty(mouse_id)
   mouse_id = glyr.img.get_mice_id(); 
end

for ts = tss
    disp("Moving rois of " +      ts.name)
    rois = ts.load_var('rois', []);
    if isempty(rois)
        warning("Skipping " + ts.name + ", no rois");
        continue;
    end

    %  Give roi category
    group_id = string(ts.name);
    category = "roitrace";
    
    % Get ts dt
    dt = rois.dff_signals.TimeInfo.Increment;
    
    % get mouse name from path name
    n = split(string(ts.path),"/");
    m = ismember(mouse_id,n);    
    if any(m)       
        mouse = string(mouse_id(m));        
    else
        mouse = "";
    end
    
    % get state name from path name
    s = ismember(states,n);
    if any(s)
        state = string(states(s));
    else
        state = "";
    end
      
    % add non doughnut substracted data (astrocytes an Np):
    non_ns_rois = rois.roi_array(string({rois.roi_array.group}) ~= "NS");
    if ~isempty(non_ns_rois)
        non_ns_data = rois.dff_signals.Data(:,string({rois.roi_array.group}) ~= "NS");
        for i = 1:length(non_ns_rois)
            trace = non_ns_data(:,i);
            trace_id = "roi-" + non_ns_rois(i).id;
            tag = "roi_group=" + non_ns_rois(i).group + "; ts_date=" +...
                string(ts.start_time) + "; roi_channel=" +...
                non_ns_rois(i).channel + "; mouse=" + mouse + "; state=" +...
                state;
            gdata.mtab.update(trace, trace_id, group_id, category, tag, "df/f", dt);
        end
    end
    
    % doughnut data (NS):
    ns_rois = rois.roi_array(string({rois.roi_array.group}) == "NS");
    if ~isempty(ns_rois)
        ns_data = rois.dff_signals_doughnut_subtracted.Data;
        for i = 1:length(ns_rois)
            trace = ns_data(:,i);
            trace_id = "roi-" + ns_rois(i).id;
            tag = "roi_group=" + ns_rois(i).group + "; ts_date=" +...
                string(ts.start_time) + "; roi_channel=" +...
                ns_rois(i).channel + "; mouse=" + mouse + "; state=" +...
                state;
            gdata.mtab.update(trace, trace_id, group_id, category, tag, "df/f", dt);
        end
    end
end

disp('mtab updated with rois')
gdata.mtab.save();
disp('mtab saved')

end



