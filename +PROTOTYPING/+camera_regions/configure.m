function configure(trials)

gui = PROTOTYPING.camera_regions.VideoGui();
gui.load_trials(trials);
assignin('base', 'VideoGUI', gui)

end