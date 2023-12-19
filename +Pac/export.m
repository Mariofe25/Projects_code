function ca_loc =  export (tss,format,out_dir)

if nargin < 3
    out_dir = uigetdir;  %'/Volumes/Xiaoyi1/PAC/Binarized data';
end

if nargin < 2
    format = "csv";
end

if format ~= "csv" && format ~= "xlsx"
    error("Export format should be 'xlsx' or 'csv'")
end

msg = fprintf('Exporting: 0 of %d', length(tss));
n = 0;
for ts = tss
    try
        n = n + 1;
        fprintf(repmat('\b',1,msg))
        msg = fprintf('Exporting: %d of %d\n', n, length(tss));
        mtab = ts.load_var('multitab');
        n_exp = unique(mtab.entity);
        save_path = fullfile(out_dir,n_exp);
        
        if ~isfolder(save_path)
            mkdir(out_dir,n_exp)
        end
        
        % time vector
        dt = unique(mtab.trace_dt);
        last_frame = unique(cellfun(@length,mtab.trace));
        time_end = last_frame * dt;
        time_vec = (0:dt:time_end-dt)';
        
        % ca_events traces
        ca_traces = mtab(mtab.category == 'ca_events',:);
        ca_traces = sortrows(ca_traces,'roi_type');
        ca_traces = ca_traces.trace';
        ca_traces = cell2mat(ca_traces);
        
        traces = [time_vec,ca_traces];
        
        % Rois type
        events_tab = ts.load_var('ca_events');
        rois_id = events_tab.id';
        %     rois_type = string(mtab.roi_type(mtab.category == 'ca_events'));
        %     r_t = unique(rois_type);
        %     for j = 1:length(r_t)
        %         r = rois_type == r_t(j);
        %         non = nonzeros(r);
        %         c = cumsum(non);
        %         rois_type(r) =  rois_type(r) + c;
        %     end
        %     rois_type = rois_type';
        
        tab_varnames = ['Time',rois_id];
        
        % binarize table
        %speed = mtab.trace(mtab.category  == 'speed');
        binar_running = mtab.trace{mtab.category  == 'running'};
        %whisker = mtab.trace(mtab.category  == 'whisker');
        binar_whisker = mtab.trace{mtab.category  == 'whisking'};
        bin_tab = table(time_vec,binar_running,binar_whisker,ca_traces);
        bin_tab = splitvars(bin_tab,'ca_traces','NewVariableName', rois_id);
        file_name = "Binarized " + string(n_exp) + "." + format;
        bin_tab_path = fullfile(save_path,file_name);
        writetable(bin_tab,bin_tab_path);
        
        % locomotion categories
        locomotion = mtab.trace{mtab.category == 'locomotion'};
        cats = categorical(categories(locomotion));
        
        cats = cats(cats~= 'Start' & cats ~= 'End');
        
        % distribute traces by locomotion cat & create/save file
        for j = 1:length(cats)
            ca_loc = traces(locomotion == cats(j),:);
            if isempty(ca_loc), continue; end
            c = string(cats(j));
            if contains(c,'/')
                c = replace(c,'/','-');
            end
            tab = array2table(ca_loc,'VariableNames',tab_varnames);
            file_name = c + "_" + string(n_exp) + "." + format;
            tab_path = fullfile(save_path,file_name);
            writetable(tab, tab_path)
        end
        
        % Get uncaging info and save as table
        if ts.has_var('uncaging_info')
            ts.load_var('uncaging_info');
            r_t = ts.load_var('rois_target');
            r_t = sortrows(r_t,{'type','shot_distance'});
            f_name = "ROI(s)-uncaging-info " +  string(n_exp) + "." + format;
            rt_path = fullfile(save_path,f_name);
            writetable(r_t,rt_path)
        end
    catch err
        disp(err.message)
        continue
    end
end
disp("Done!")
end