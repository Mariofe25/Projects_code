function get_satb_template(ts)

% Get a template to later stabilize tseries of the same FoV

if ts.has_var('normcore_config')
    options = ts.load_var('normcore_config');
else
    options = begonia.processing.motion_correction.AlignmentSettings(ts);
end

alignment_channel = options.channel;

nc_params = options.nc_params;
% Set the output type to H5 as this function is ment to run lazily.
nc_params.output_type = 'h5';
% Specify where the temporary data from normcore will be saved. 
nc_params.h5_filename = sprintf('motion_corrected_ch%d.h5',alignment_channel);

% Fool NoRMCorre to read data lazily by mimmicking memmap. NoRMCorre
% assumes the output from memmap is single. 
mat = ts.get_mat(alignment_channel);
obj = begonia.processing.motion_correction.DummyMemmap();
obj.Y = mat;

% Delete the output files from NoRMCorre if they are left over from a 
% previous run.
for ch = 1:ts.channels
    motcor_filename = sprintf('motion_corrected_ch%d.h5',ch);
    if exist(motcor_filename,'file')
        delete(motcor_filename);
    end
end

% Supress warnings when writing single to uint16 in hdf5. 
warning off
[~,~,template,~] = normcorre(obj,nc_params);
warning on

ts.save_var('Stab_template',template)
ts.save_var('Stab_template_origin', ts.path)
end