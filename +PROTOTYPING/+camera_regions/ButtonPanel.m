classdef ButtonPanel < handle
    %BUTTONPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        panel
        pad_margin
        pad_button
        button_height
    end
    
    properties
        row_idx = 1
    end
    
    methods
        function self = ButtonPanel(panel)
            self.panel = panel;
            switch panel.Units
                case 'centimeters'
                    self.pad_margin = 0.5;
                    self.pad_button = 0.25;
                    self.button_height = 1;
                otherwise
                    error('Todo: Add more inital spacing values.')
            end
        end
        
        function reset(self)
            self.row_idx = 1;
        end
        
        function add_graphics_object(self,go)
            go.Parent = self.panel;
            go.Units = self.panel.Units;
            go.Position(1) = self.pad_margin;
            go.Position(2) = self.panel.Position(4) ...
                - self.pad_margin ...
                - self.button_height ...
                - (self.row_idx - 1)*(self.button_height + self.pad_button);
            go.Position(3) = self.panel.Position(3) - 2*self.pad_margin;
            go.Position(4) = self.button_height;
            self.row_idx = self.row_idx + 1;
        end
    end
    
end

