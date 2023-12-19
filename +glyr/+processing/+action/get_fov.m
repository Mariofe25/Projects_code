function get_fov(dlocs,model,editor)
import glyr.processing.*
if isempty(dlocs) || length(dlocs) == 1
    dlocs = model.dlocs;
end
glyr.img.get_frame_position(dlocs)

place_new_var(editor,'FoV','stabilized')
end





