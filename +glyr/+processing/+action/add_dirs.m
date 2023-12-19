function add_dirs(~, model, editor)
path = glyr.processing.uigetdirn([],"Select data directories");
if isempty(path)
    return;
end
h = waitbar(0.1, "Locating data (might take a while)");
scans = cell(1,length(path));
for i = 1:length(path)
    scans{i} = begonia.scantype.find_scans(path{i});
end
scans = [scans{:}];
model.dlocs = [model.dlocs, scans];
editor.datagrid.reloadTable();
delete(h);
end

