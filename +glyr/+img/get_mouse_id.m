function get_mouse_id(tss,mice_id)
% Find the corresponding mouse name. It uses the mice names list (mice_id)
if nargin < 2, mice_id = glyr.img.get_mice_id;end
for ts = tss
    ts_path = string(ts.path);
    ts_path = split(ts_path,"/");
    m_idx = ismember(mice_id,ts_path);
    mouse  = mice_id(m_idx);
    ts.save_var("mouse",mouse)  
end
end