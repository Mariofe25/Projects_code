function extract_whisker_rois(trials)
% extract the data from whisker rois and save them. The more trials the
% more time it will take to run (30s-1min for 3000-6000 frames). But once
% data has been saved (trials/metadata), it will be much faster to retrieve
% it.
for trial = trials
    try
        if trial.has_var('Knut_whisk')
            if trial.dl_changelog('Knut_whisk') < trial.changelog('camera_regions')
                w = yucca.mod.camera_regions.read(trial);
                whisk = w.whisker;              
                trial.save_var('Xiaoyi_whisk',whisk)
            end
        end
    catch err
        disp(err.message)
        continue
    end
end
end