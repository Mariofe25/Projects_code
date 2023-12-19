classdef Rig_Editor < xylobium.dledit.Editor
      %Detailed explanation goes here
    
    properties
        trials yucca.trial.Trial 
    end
    
    methods
        function obj = Rig_Editor(trials)
            import glyr.rig.*;
            actions = Rig_Editor.get_default_actions();
            vars = {'name','path', 'video_region_mask','laser_data','laser_onset','wheel_trim','whisking_trim','puptrack_data','pupil_trim'};
            obj = obj@xylobium.dledit.Editor(trials, actions, vars);           
            obj.trials = trials;
        end
        
    end
    
    methods (Static)
        
        function actions = get_default_actions()
            import xylobium.dledit.*;
            import glyr.rig.laser.*;
            import glyr.rig.pupil.*;
            import glyr.rig.wheel.*;
            import glyr.whisker.*;
            
            ac_laser_roi = Action(...
                '(1)Draw Laser roi', @(d, m, e) draw_laser_roi(d), false, true, 'control-shift-l');
            
            ac_on = Action(...
                '(2)Get Laser Data/Onset', @(d, m, e) get_onset(d), true, false, 'control-shift-o');
            
            ac_wheel_trim = Action(...
                '(3)Trim wheel', @(d, m, e) trim_wheel(d), true, false, 'control-shift-s');
            
            ac_pupil_trim = Action(...
                '(3)Trim pupil', @(d, m, e) trim_pups(d), true, false, 'control-shift-p');
            
             ac_whisking_trim = Action(...
                '(3)Trim whisking', @(d, m, e) trim_whisking(d), true, false, 'control-shift-w');
            
            ac_crop_pupil = Action(...
                'Crop pupil', @(d, m, e)  make_pupil_video(d), true, false, 'control-shift-m');
            
            
            
            actions = [ ...
                ac_laser_roi ac_on  ac_wheel_trim ac_pupil_trim ac_whisking_trim ac_crop_pupil] ;
        end
    end
end
