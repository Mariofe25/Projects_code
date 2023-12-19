classdef Rig_Editor < xylobium.dledit.Editor
    %Detailed explanation goes here

    properties
        trials yucca.trial.Trial
    end

    methods
        function obj = Rig_Editor(trials)
            import Pac.rig.*;
            actions = Rig_Editor.get_default_actions();
            vars = {'name','path','video_region_mask','laser_data','laser_onset','wheel','wheel_trim','speed','whisking','whisking_trim'};
            obj = obj@xylobium.dledit.Editor(trials, actions, vars);
            obj.trials = trials;
        end

    end

    methods (Static)

        function actions = get_default_actions()
            import xylobium.dledit.*;
            import Pac.rig.*;
     
            ac_laser_roi = Action(...
                '(1)Draw ROIs', @(d, m, e) draw_laser_roi(d), false, true, 'control-shift-l');

            ac_on = Action(...
                '(2)Get Laser Data/Onset', @(d, m, e) get_onset(d), true, false, 'control-shift-o');

            ac_wheel_trim = Action(...
                '(3)Trim wheel', @(d, m, e) trim_wheel(d), true, false, 'control-shift-s');

            ac_get_speed = Action(...
                'Get speed (cm/s)', @(d,m,e)  get_speed(d),true,false,'control-shift-g');

            ac_whisking_trim = Action(...
                '(3)Trim whisking', @(d, m, e) trim_whisking(d), true, false, 'control-shift-w');

            
            actions = [ ...
                ac_laser_roi ac_on  ac_wheel_trim  ac_get_speed ac_whisking_trim] ;
        end
    end
end
