function  copy_roi_table(tss)
% maybe change so that it copy depending on date of recording and frames
% position [x,y,z];


try
roi_tabs = tss.load_var('roi_table');
catch
  
end
[~, idx] = max(cellfun(@height,roi_tabs));
roi_table = roi_tabs{idx};
tss2do = tss(:,1:end ~= idx);
for ts = tss2do
    if ts.has_var('roi_table')
        rt = ts.load_var('roi_table');
        ts.save_var('roi_table_old',rt);
    end  
    roi_tab = roi_table;
    n_rois = height(roi_tab);
    rois_uuids = create_nuuid(n_rois);
    roi_tab.roi_id = rois_uuids;
    ts.save_var('roi_table',roi_tab)   
end
end

function uuid =  create_nuuid(n)
uuid = cell(n,1);
for i = 1:n
    random_uuid = java.util.UUID.randomUUID;
    random_uuid = char(random_uuid);
    uuid{i} = random_uuid;
end
uuid = string(uuid);
end