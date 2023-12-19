function  rois_to_mtab(tss, nordata,mouse_id,state_id)

    for ts = tss
        disp(ts.name)
        rois = ts.load_var('rois', []);
        if isempty(rois)
            warning("Skipping " + ts.name + ", no rois");
            continue;
        end
        
        group_id = string(ts.name);
        category = "roitrace";
        dt = rois.dff_signals.TimeInfo.Increment;
        
        % take mouse name from path name
        m = split(string(rois.ts_path),"/");
        m = ismember(mouse_id,m);
        
        if any(m)
            
            mouse = mouse_id(m);
            
        else
            mouse = [];
            
        end
        
       %take state name from path name
       
        m = split(string(rois.ts_path),"/");
        s = ismember(state_id,m);
        
        if any(s)
            
            state = state_id(s);
            
        else 
            
            state = "?";
        end
            
       
     

        % add non doughnut substracted data:
        non_ns_rois = rois.roi_array(string({rois.roi_array.group}) ~= "NS");
        non_ns_data = rois.dff_signals.Data(:,string({rois.roi_array.group}) ~= "NS");
        
        for i = 1:length(non_ns_rois)
            trace = non_ns_data(:,i);
            trace_id = "roi-" + non_ns_rois(i).id;
            tag = "roi_group=" + non_ns_rois(i).group + "; ts_date=" + string(ts.start_time) + "; roi_channel=" + non_ns_rois(i).channel + ";mouse=" + string(mouse) + ";state=" + string(state); 
            nordata.mtab.update(trace, trace_id, group_id, category, tag, "df/f", dt);
        end
        
        % doughnut data:
        ns_rois = rois.roi_array(string({rois.roi_array.group}) == "NS");
        ns_data = rois.dff_signals_doughnut_subtracted.Data;
        
        for i = 1:length(ns_rois)
            trace = ns_data(:,i);
            trace_id = "roi-" + ns_rois(i).id;
            tag = "roi_group=" + ns_rois(i).group + "; ts_date=" + string(ts.start_time) + "; roi_channel=" + ns_rois(i).channel + ";mouse=" + string(mouse)+ ";state=" + string(state); 
            nordata.mtab.update(trace, trace_id, group_id, category, tag, "df/f", dt);
        end
        
%         
%         for i = 1:length(rois.roi_array)
%             
%             trace_id = "roi-" + rois.roi_array(i).id;
%             
% %             trace = rois.dff_signals.Data(:,i);
% 
%            
% 
%             if rois.roi_array(i).group == "NS"
%                  new_dff = rois.dff_signals.Data(:,i);
%             else
%                 new_dff = rois.dff_signals.Data(:,i);
%             end
%             
%             if ~isempty(rois.dff_signals_doughnut_subtracted)
%                 
%                 new_dff = rois.dff_signals.Data(:,i);
%                 
%                 new_dff(:,{rois.roi_array.group} == "NS")= ...
%                     rois.dff_signals_doughnut_subtracted.Data;
%             end
%             
%             trace = new_dff;
%             
%             tag = "roi_group=" + rois.roi_array(i).group + "; ts_date=" + string(ts.start_time) + "; roi_channel=" + rois.roi_array(i).channel; 
%             
%             gdata.mtab.update(trace, trace_id, group_id, category, tag, "df/f", dt);
%         end
    end

    nordata.mtab.save();
end



