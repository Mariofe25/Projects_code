% % Analysis pipelne WT/IP3KO -/-
begonia.logging.set_level(1)

%% open data in datamanger or load tseries by virus expression
Pac.processing.dataman

% ... or load the different datasets (just one at a time)
Pac.processing.load_denoised_wt_tss
Pac.processing.load_denoised_ip3r2ko_tss
% TBD add ip3r2ko uncaging

Pac.processing.load_wt_tss
Pac.processing.load_ip3ko_tss
%% Preprocessing steps

% Stablize 
% do it on datamanager

% Denoise (this has been donde using SUPPORT. Stabilzed tseries were
% converted to tiff stacks and splitted in 2 channels. After training few
% tseries with SUPPORT, rest of the tseries were denoises with the trained
% model. Once denoised the splitted channel were put toguther again and
% metadata from coresponding h5 tseries was copied into their metadata
% folder
% * tseries are copied and denoise in a workstation that supports CUDA

% Converted to tiff and split channels ==> Denoise
Pac.img.ts2tiff_split_ch(tss);

% Once denoised... Concatenate channels  
Pac.img.concatenate_tstiff_chs 

% Copy metadata
vars = ["roi_table","associated_trial","mouse","genotype"];
%tsstiff_path = '/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/Denoised_wt';
tsstiff_path = '/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/Denoised_Ip3r2ko';
tsstiff = begonia.scantype.find_scans(tsstiff_path);
Pac.img.move_metadata_vars(tss,tsstiff,vars)

%% Process ROIs

% Process rois in the datamanger or use functions:
% Extract NS donut raw signals (neuropil contamination)
Pac.img.extract_neuropil_rois(tss);

% Calulate ∆F/F, includes neuropil substraction for NS ROIs
Pac.img.extract_roi_dff_signals(tss);

% Inference of spike probability for NS signals. Use Cascade. 
% Export NS ∆F/F traces for inference (signals already with neuropil
% subtracted)
Pac.img.export_ns_dF_traces(tss);

% Import spike prob inference to tss metadata
Pac.img.import_spikes_prob(tss);

%% Rig proccesing

% Find the TSeries associated trials
% this only works if trials-tss have been associated previously
trials = Pac.rig.get_trials(tss);
trials = [trials{:}];

% if not  associated;
trials_path = '/Volumes/Xiaoyi1/PAC/wheel data'; % change path if necessary
trials = yucca.trial_search.find_trials(trials_path);
t = yucca.util.correlate_ts_trial(tss,trials);
Pac.rig.save_associated_trials(tss,t);
trials = Pac.rig.get_trials(tss);
trials = [trials{:}];

% Check tseries and asscoiated trials time correlation
Pac.rig.check_ts_trial_corr(tss,trials);

% Mark laser and whiskers (use Rig Editor to do this).
% Rig Editor can  trim the wheel and whisker traces to the laser onset 
% (to sync 2p recordings and behaviour data). Also calculate speed in cm/s
% GUI
Pac.rig.Rig_Editor(trials);

% Alternatively (code)
Pac.rig.draw_laser_roi(trials);
Pac.rig.get_onset(trials);
Pac.rig.trim_wheel(trials);
Pac.rig.get_speed(trials);
Pac.rig.trim_whisking(trials);

% Classify locomotion (aka behaviour state when combine w/whisking )
Pac.rig.segment_locomotion(trials);
Pac.rig.correct_locomotion_seg(trials);

%---------------------------
% Whisker Analysis
% Binarize whisking (Whisking state)
Pac.rig.binarize_whisk(trials);

%% Move data to multitable
% Multitab gathers all dataset info (TSeries + Rig data). As a table
% allows filters to analyze data by groups (e.g.,exp state, mouse, fov, roi_type,...)

% Create multitab
fs = 10;
Pac.move2multitab(tss,trials,fs); 

% Find events (find events in multitab traces)
Pac.img.find_events(tss);  
% This step could have been done before....
% glyr.find_rois_events(tss); % find events in rois' dff traces (before adding to mtab)

% smooth ca traces (optional)
Pac.img.smooth_ca(tss); % use before segemnting for rMI,wMI 

% Segment multitable by behaviour state
Pac.segment_mtab(tss); 

% Now that it is segmented, events are repeated in different rows from the 
% same ROI. Filter segment events
Pac.filter_mtabseg_events(tss); 

% Merge segments that share the same roi id and behav state 
mtab = Pac.mtab_merge_states(tss,0,3); % (tss,get_positive_glyr,do_filter,3secs minimum)

% as it can take some time to get the merged multitable, save it. However, if
% somehting in the analysis change, it has to be updated
gen = unique(string(tss.load_var("genotype")));
mp = fullfile("/Volumes/Xiaoyi1/PAC","multitabs");  
mtab_path = fullfile(mp,gen + "_merged.mat");
begonia.path.make_dirs(mtab_path)
save(mtab_path,"mtab")
load(mtab_path)

%% Plots
% Plot signals overview, behaviour (speed and whisking) + ∆F/F heatmap
Pac.plot.plot_data_overview(tss,1);

% Plot behaviour overview by mouse
Pac.rig.get_behav_rate(tss,1);
Pac.rig.video_behav_state(tss);

% Get events features in neurons/astrocytes by behav state (all segs combined)
% frequency, number of rois
Pac.plot_events_by_behaviour(mtab,1);

% Events features
Pac.plot_event_features(mtab,1);

% Plot event onset
Pac.plot_events_onset(tss);

% Plot spike probability (Cascade)
Pac.plot_spike_probablity_bybehav(mtab);

% Plot spike probaility from transition to locomotion (by sec)
Pac.

%% Modulatory Index (locMI & wMI)
% Locomotion MI (locMI)
Pac.MI;
glyr.wMI(mtab,0,0,4,1,1) % wMI(mtab,do_by_entity,do_max,still_secs,do_plots,do_save)

%% Transition to Locomotion
Pac.align2locon(tss);
Pac.make_transition_tab(tss);

% Events onset from locomotion onset.Heatmap
Pac.transition2locomotion(tss,1);

% Plot the ∆F/F traces during the trans to loc (6sec locomotion)
Pac.plot_trans2loc(tss,0,1);

% only active rois
Pac.plot_trans2loc(tss,1,1);