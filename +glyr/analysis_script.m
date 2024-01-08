% Analysis pipelne
begonia.logging.set_level(1)

%% open data in datamanger or load tseries by virus expression
glyr.processing.dataman
% Make sure all the tseries with the same fov have the same rois, otherwise
% there will be some error when creating the multitabs and plots

% ... or load the different datasets (just one at a time)
% glyr.processing.load_noIVM_tss
% glyr.processing.load_IVM_tss
% glyr.processing.load_postIVM_tss
% glyr.processing.load_no_GlyR_noIVM_tss
tss = glyr.processing.load_dataset("noIVM");
tss = glyr.processing.load_dataset("IVM");
tss = glyr.processing.load_dataset("postIVM");
tss = glyr.processing.load_dataset("no_GlyR_noIVM");
tss = glyr.processing.load_dataset("no_GlyR_IVM");
tss = glyr.processing.load_dataset("no_GlyR_postIVM");

%% After processing the rois in the datamanager
% Process rois int eh datamanger or use functions:
% Extract donut dff
glyr.img.extract_neuropil_rois(tss);

% Calulate ∆F/F, includes neuropil substraction for NS ROIs
glyr.img.extract_roi_dff_signals(tss);

% Inference of spike probability for NS signals. Use Cascade. 
% Export NS ∆F/F traces for inference (signals already with neuropil
% subtracted)
glyr.img.export_ns_dF_traces(tss);

% Import spike prob inference to tss metadata
glyr.img.import_spikes_prob(tss);

%% Rig proccesing

% Find the TSeries associated trials
% this only works if trials-tss have been associated previously
trials = glyr.rig.get_trials(tss);
trials = [trials{:}];

% if not  associated;
trials_path = "/Volumes/GlyR/GlyR project/Rig"; % change path if necessary
trials = yucca.trial_search.find_trials(trials_path);
t = yucca.util.correlate_ts_trial(tss,trials);
glyr.rig.save_associated_trials(tss,t);
trials = glyr.rig.get_trials(tss);
trials = [trials{:}];

% Mark laser and whiskers (use Rig Editor to do this).
glyr.rig.Rig_Editor(trials);
% Also in the rig editor it is possible to trim the wheel and whisker
% traces to the laser onset (to sync 2p recordings and behaviour data)

% Locomotion analysis
% Get speed (* it in deg/s. When ploting is transform to cm/s)
glyr.rig.wheel.get_speed(trials);

% Classify locomotion (aka behaviour state when combine w/ whisking )
glyr.rig.binarize_locomotion_v2(trials);
glyr.rig.correct_locomotion_seg(trials);

%---------------------------
% Whisker Analysis
% Binarize whisking (Whisking state)
glyr.whisker.binarize_whisk(trials);

% Classify Experiment state (Baseline,Stimulation,Post)
glyr.whisker.whisk_log(trials);

%--------------------------
% Pupil Analysis
% 1. Crop eye area for analysis
glyr.rig.pupil.pupil_crop(trials);

% 2. Make video of cropped area
for trial = trials
    glyr.rig.pupil.make_pupil_video(trial);
end

% 3. Move videos to analysis folder
pup_path = "/Volumes/GlyR/pupil/noIVM"; % change depending on the dataset (IVM, no_GlyR...)
glyr.rig.pupil.move_pup2analysis(trials,pup_path)

% Analysis is done with DLC. Config file with the trained model is here:
% '/Volumes/GlyR/pupil_measure/pupil_size-Mario-2022-06-22/config.yaml'
% It can be done with code or the GUI. To use the GUI, activate the
% DLC enviroment in the terminal and use the command 'pythonw -m
% deeplabcut'. Load the project with the config file and choose the videos
% in the 'anlyze videos' tab. Optionally create videos with labels of the
% tracked pupil

% 4.Get tracked pupil size (csv file). Move to trial metadata
filtered = 1; % use filtered predictions
pup_path = "/Volumes/GlyR/pupil_videos/noIVM";
glyr.rig.pupil.move_pup2trial(trials,pup_path,filtered) % Change path if needed)

% Move video with labeled pupils to trials path
pup_path = "/Volumes/GlyR/pupil/no_GlyR"; % change depending on dataset (noIVM,IVM...)

glyr.rig.pupil.pupvid_tracked_move2trial(trials,pup_path);

% 5. Calculate diameter by fitting a circle from coords. Check 
% the likelihood. Calcualte the average diameter and pupil to eye ratio
% (to deal with possible diffence in mouse face-camera position)
% glyr.rig.pupil.pupil_diameter_v1(trials) old version
glyr.rig.pupil.pupil_diameter(trials);

% 6. Trim pupil diameter trace (to laser onset). Can also be done with
% doable in RigEditor
glyr.rig.pupil.trim_pups(trials);

%% Move data to multitable
% Multitab gathers all dataset info (TSeries + Rig data). As a table
% allows filters to analyze data by groups (e.g.,exp state, mouse, fov, roi_type,...)

% Create multitab
glyr.move2multitab(tss,trials); 

% Find events (find events in multitab traces)
glyr.find_events(tss);  
% This step could have been done before....
% glyr.find_rois_events(tss); % find events in rois' dff traces (before adding to mtab)

% smooth ca traces (optional)
glyr.smooth_ca(tss); % use before segemnting for rMI,wMI 

% Segment multitable by experimental state and behaviour state
glyr.mtab_segmentation(tss); 

% Now that it is segmented, events are repeated in different rows
% (segments). Filter segment events
glyr.filter_mtab_events(tss); % multitab_segmented

% Merge segments that share the same roi id,experemintal state, behav state 
% and FoV
mtab = glyr.mtab_merge_states(tss,0,0,3); % (tss,get_positive_glyr,do_filter,3secs minimum)

%% Plots
% Plot dff
glyr.plot.plot_activity_rois(tss,1);

% Plot neurons events
glyr.plot_rois_events(mtab,"neurons",1)

% Plor astrocytes events
glyr.plot_rois_events(mtab,"astrocytes",1)

% Plot events by fov
glyr.plot.plot_fov_summary(mtab,1);

% Get summary of events activity in neurons/astrocytes by behav state (all fovs combined)
glyr.summary_paired_events_plots;
glyr.summary_paired_events_tabs;
glyr.event_features_paired;
glyr.summary_paired_spikes;
% glyr.sum_paired_event_tabs;

% Plot summary roi event not paired (by roi type, behav and experimetal state)
glyr.summary_unpaired_events_plots;
glyr.summary_unpaired_events_tabs;
glyr.event_features_unpaired;
glyr.summary_unpaired_spikes;

% Plot summary of roi events (un/paired) by mouse and by FoV
glyr.summary_mouse_fov_events;

% Plot event onset
glyr.events_corr2(tss);

%% Modulatory Index (locMI & wMI)
% Locomotion MI (locMI)
glyr.MI % Run for each IVM state. Do this manually, not all combinations are possible
glyr.wMI(mtab,0,0,4,1,1) %wMI(mtab,do_by_entity,do_max,still_secs,do_plots,do_save)

%% Transition to Stimulation
glyr.noIVM_trans2stim
glyr.IVM_trans2stim      

%% Transition to Locomotion
glyr.align2locon(tss,"Baseline")
glyr.make_transition_tab_pupil(tss,"Baseline")

% Events onset from locomotion onset
glyr.evs_onset_loc_v2(tss,"Baseline",0.25,1,1,1,0,1,0,1)

% plot the df/f traces during the trans to loc
glyr.plot.plot_trans2loc(tss,"Baseline",0,1)
glyr.plot.plot_trans2loc(tss,"Baseline",1,1)

% Stimulation
glyr.align2locon(tss,"Stimulation")
glyr.make_transition_tab_pupil(tss,"Stimulation")
glyr.evs_onset_loc_v2(tss,"Stimulation",0.25,1,1,1,1)
glyr.plot.plot_trans2loc(tss,"Stimulation",0,1)
glyr.plot.plot_trans2loc(tss,"Stimulation",1,1)

%% Events onset - Pupil onset


