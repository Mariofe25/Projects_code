function write_vars(trials)

fprintf('Attempting to load camera regions:\n');
for trial = trials
    try
        camera_regions = yucca.mod.camera_regions.read(trial);
        trial.save_var(camera_regions);
    catch e
        fprintf('Trial: %s\n',trial.path);
        fprintf('Error: %s\n',e.identifier);
    end
end


end

