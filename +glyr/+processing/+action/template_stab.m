function template_stab(dloc,model,editor)
% if isempty(dlocs)
%     tss = model.dlocs;
%     fovs = dlocs.load_var("FoV");
%     fovs = cell2mat(fovs);
%     [~,d,~] = unique(fovs,"stable");
%     dlocs = tss(d);
% end
import glyr.processing.*
disp("Getting stabilization template from " + dloc.path)
glyr.processing.get_satb_template(dloc)
tss = model.dlocs_filtered;
fov_master = dloc.load_var("FoV");
fovs = tss.load_var("FoV");
fovs = cell2mat(fovs);
idx = fovs == fov_master;
ts_fov = tss(idx);
template = dloc.load_var('Stab_template');
ts_fov.save_var('Stab_template',template)
ts_fov.save_var('Stab_template_origin', dloc.path)

place_new_var(editor,'Stab_template','stabilized')
end



