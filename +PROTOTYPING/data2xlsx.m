function data2xlsx(traces)

for i = 1:height(traces)
    
    rois = traces.rois{i};
    
    % time
    Time = seconds(rois.dff_signals.Time);
    
    % roi traces and clear empty rois
    AS = rois.dff_signals.Data(:,{rois.roi_array.group} == "AS");
    AS = AS(:,any(AS));
    AE = rois.dff_signals.Data(:,{rois.roi_array.group} == "AE");
    AE = AE(:,any(AE));
    AP = rois.dff_signals.Data(:,{rois.roi_array.group} == "AP");
    AP = AP(:,any(AP));
    GP = rois.dff_signals.Data(:,{rois.roi_array.group} == "Gp");
    GP = GP(:,any(GP));
    NS = rois.dff_signals.Data(:,{rois.roi_array.group} == "NS");
    NS = NS(:,any(NS));
    NP = rois.dff_signals.Data(:,{rois.roi_array.group} == "Np");
    NP = NP(:,any(NP));
    NSs = rois.dff_signals_doughnut_subtracted.Data;
    NSs = NSs(:,any(NS));
    
  
%   Create timetable of rois and remove empty roi groups
    rois_timetab = timetable(Time,AS,AE,AP,GP,NS,NP,NSs);
    
    vname = rois_timetab.Properties.VariableNames;
    
    for ii = 1:length(vname)
        
        if isempty(rois_timetab.(vname{ii})) == 1
            
            rois_timetab.(vname{ii}) = [];
        end
    end
    
    rois_timetab = retime(rois_timetab,"regular","linear","SampleRate",10);
    
    % wheel trace (delta angle)
    wheel = traces.wheel{i};
    wheel_timetab = timetable(seconds(wheel.DeltaAngle.Time),wheel.DeltaAngle.Data*-1,...
        'Variablenames',{'Wheel_DeltaAngle'});
    wheel_timetab = retime(wheel_timetab,"regular","linear","SampleRate",10);
    
    % whiskers roi
    whisker = traces.rois_whisker{i};
    whisker_timetab = timetable(seconds(whisker.Time),whisker.whisker.Data,...
        'VariableNames',{'Whiskers_roi'});
    whisker_timetab = retime(whisker_timetab,"regular","linear","SampleRate",10);
    
    % join wheel_timetab and whisker_timetab (trim data to the equal the smallest timetab)
    
    rig_data = synchronize(wheel_timetab,whisker_timetab,"commonrange");
    
    % join rig_data timetab with roi_timetab (triim)
    data = synchronize(rig_data,rois_timetab,"commonrange");
    
    % transform to table to convert time column to numeric
    t = seconds(data.Time);
    data = timetable2table(data);
    data.Time = t;
    
    % create and save excel sheet
    folder_path = '/Volumes/Disk 2/PAC/Metadata/Data sheets';
    file_name = rois.ts_name + ".xlsx";
    file_path = fullfile(folder_path,file_name);
    writetable(data,file_path)
    disp("excel shit created for " + rois.ts_name)
end

end