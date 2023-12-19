function stabilize_by_template(ts, model, editor)
if exist("NoRMCorreSetParms") ~= 2
    msgbox("Error: NoRMCOrre is not installed - see documentation.");
    return;
end

if ts.has_var('normcore_config')
    config = ts.load_var('normcore_config');
else
    config = begonia.processing.motion_correction.AlignmentSettings(ts);
end

% Save the stabilized tseries at the same location but with
% "_stabilized" added to the filename.
[d,f] = fileparts(ts.path);
output_path = fullfile(d,[f,'_stabilized']);
if ts.has_var('Stab_template')
    template = ts.load_var('Stab_template');
else
    error(ts.name + " does not have a stabilization template. " ...
        + " Get it by copy/pasting from 1st recording of the FoV")
end

ts_stabilized = glyr.processing.run_normcorre_by_template(ts,output_path,config,'h5',template);
editor.add_dlocs(ts_stabilized);
end

