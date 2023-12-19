function state = get_state(path)
dirs = dir(path);
m_n = {dirs.name};
mice_id = m_n(m_n ~= "." & m_n ~= "..");
end