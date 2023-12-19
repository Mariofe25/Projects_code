function video_behav_state(tss)
% Marks the surveillance video frames with behaviour states
% Addapted from Daniel

import  begonia.logging.log
log(1,"Making videos with behaviour states marked...")
for ts = tss
    gen = string(ts.load_var("genotype"));
    log(1,ts.name)
    trial = glyr.rig.get_trials(ts);
    trial = trial{:};
    loc_episodes = trial.load_var("locomotion_tab");
    whisk_episodes = trial.load_var("whisking_tab");
    laser_onset = trial.load_var("laser_onset");
    
    trial_path = trial.path;
    trial_path = string(trial_path);
    
    camera_file = trial_path + "/camera.avi";
    camera_t_file = trial_path + "/camera_time.csv";
    
    % Calculate the time vector.
    camera_t = dlmread(camera_t_file, ',', 22, 1);
    camera_t = camera_t(:,1)'/1000;
    camera_t = camera_t - camera_t(1);
    
    % Decide which frames to show.
    video_fps = 30;
    video_speed = 1;
    duration = camera_t(end) - camera_t(1);
    camera_dt_out = video_speed / video_fps;
    camera_t_out = round(laser_onset):camera_dt_out:duration;
    camera_I = begonia.util.val2idx(camera_t, camera_t_out);
    
    % Update time episodes to fit
    loc_episodes.end_sec(end) = duration;
    whisk_episodes.end_sec(end) = duration;
    
    % Make file.
    p = "/Volumes/Xiaoyi1/PAC/Analysis/Behaviour_state/Video_" + gen;
    camera_file_out =  "Behaviour_state_ " + ts.name + ".mp4";
    path = fullfile(p,camera_file_out);
    begonia.path.make_dirs(path);
    
    % Start writing.
    v = VideoReader(camera_file);
    v_out = VideoWriter(path, 'MPEG-4');
    v_out.FrameRate = video_fps;
    v_out.Quality = 20;
    v_out.open();
    
    % Loop through frames.
    tic
    for frame = 1:length(camera_I)
        % Print
        if toc > 5 || frame == 1 || frame == length(camera_I)
            tic
            log(1,"Reading frame %d/%d (%.f%%)", ...
                camera_I(frame), ...
                camera_I(end), ...
                camera_I(frame) / camera_I(end) * 100);
        end
        im = v.read(camera_I(frame));
        
        % Get the state the frame is in.
        loc_idx = loc_episodes.start_sec <= camera_t_out(frame) ...
            & loc_episodes.end_sec > camera_t_out(frame);
        
        whisk_idx =  whisk_episodes.start_sec <= camera_t_out(frame) ...
            &  whisk_episodes.end_sec > camera_t_out(frame);
        
        text = string(loc_episodes.locomotion_state(loc_idx));
        t = string(whisk_episodes.whisk_state(whisk_idx));
        if isempty(text)
            text = "Missing state";
        end
        
        if isempty(t)
            t = "";
        end
        im = insertText(im,[0,60],t,"FontSize",20,'BoxColor','white');
        im = insertText(im,[0,0],text,"FontSize",20);
        im = imresize(im,0.5);
        v_out.writeVideo(im);
    end
    v_out.close();
end
end