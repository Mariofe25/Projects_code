classdef Whisker_Editor < xylobium.dledit.Editor
    %   Detailed explanation goes here
    
    properties
        tss
    end
    
    methods
        function obj = Whisker_Editor(tss)
            import glyr.whisker.*;
            actions = Whisker_Editor.get_default_actions();
            vars = {'name','path','whisker_path','whisk_metadata'};
            obj = obj@xylobium.dledit.Editor(tss, actions, vars);
            obj.tss = tss;
        end
        
    end
    
    methods (Static)
        
        function actions = get_default_actions()
            import xylobium.dledit.*;
            import glyr.whisker.actions.*;
            
            ac_fw = Action(...
                '(1)Find whisker data', @(d, m, e) get_whisker_path(d), true, false, 'control-shift-f');
            
            ac_h5 = Action(...
                '(2)Extract, Downsample & Transform2H5', @(d, m, e) edt_whisker_data(d), true, false, 'control-shift-o');
            
            actions = [ac_fw ac_h5] ;
        end
    end
end
