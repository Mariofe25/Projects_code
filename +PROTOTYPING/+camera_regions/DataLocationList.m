classdef DataLocationList < handle
    
    properties
        panel
        listbox_dlocs
        
        button_panel
        dlocs
        dloc_names
    end
    
    methods
        
        function self = DataLocationList(varargin)
            p = inputParser;
            p.addOptional('fig',[], ...
                @(x) validateattributes(x,{'matlab.ui.Figure'},{}));
            p.addOptional('panel_limits',[5,15], ...
                @(x) validateattributes(x,{'numeric'},{'numel',2}));
            p.addOptional('panel_units','centimeters', ...
                @(x) begonia.validators.validatestring(x,{'centimeters'}));
            p.addOptional('drawbuttons',1, ...
                @(x) validateattributes(x,{'numeric'},{'numel',1}));
            p.parse(varargin{:});
            begonia.util.dump_inputParser_vars_to_caller_workspace(p);
            %% figure setup
            if isempty(fig)
                create_figure = true;
            else
                create_figure = false;
            end
            
            if create_figure
                fig = figure;
                fig.Name = 'Data Location List';
                fig.NumberTitle = 'off';
                fig.MenuBar = 'none';
                fig.Units = 'centimeter';
            end
            
            %% panel
            
            
            if drawbuttons == 1
                panel = uipanel;
                panel.Parent = fig;
                panel.Units = 'centimeter';
                panel.Position(1:2) = [1,1] + [panel_limits(1),0] + [1,0];
                panel.Position(3:4) = panel_limits;
                self.panel = panel;
                button_panel = begonia.gui_tools.ButtonPanel(panel);
                self.button_panel = button_panel;
                if create_figure
                    fig.Position = [5,5,panel.Position(3)+2,panel.Position(4)+2];
                end
            else
                if create_figure
                    fig.Position = [5,5,10,10];
                end
            end
            
            
            
            %% gui components
            listbox_dlocs = uicontrol('Style','listbox');
            listbox_dlocs.Parent = fig;
            listbox_dlocs.Units = 'centimeters';
            listbox_dlocs.Position(1:2) = [1,1];
            listbox_dlocs.Position(3:4) = panel_limits;
            listbox_dlocs.Max = 999999;
            listbox_dlocs.Min = 0;
            self.listbox_dlocs = listbox_dlocs;
            
            %             pushbutton_remove_rois = uicontrol('Style','pushbutton');
            %             pushbutton_remove_rois.String = 'Remove ROI';
            %             pushbutton_remove_rois.Callback = @(s,e) self.remove_roi_by_idx(self.listbox_dlocs.Value);
            %             button_panel.add_graphics_object(pushbutton_remove_rois);
            %             self.pushbutton_remove_rois = pushbutton_remove_rois;
            %
            %             pushbutton_save_rois = uicontrol('Style','pushbutton');
            %             pushbutton_save_rois.String = 'Save ROIs';
            %             pushbutton_save_rois.Callback = @(s,e) self.save_rois();
            %             button_panel.add_graphics_object(pushbutton_save_rois);
            %             self.pushbutton_save_rois = pushbutton_save_rois;
            
            %% Size adjustment
            if create_figure
                begonia.gui_tools.autosize_container(fig,0.5);
                set(findall(fig, '-property', 'Units' ), 'Units', 'Normalized')
            end
            
            
        end
        
        
        function load(self,dlocs,names)
            if nargin < 3
                %names = {dlocs.path};
                names = {dlocs.name};
%                 max_char_length = 25;
%                 for i = 1:length(names)
%                     str = names{i};
%                     while length(str) > max_char_length
%                         str = strsplit(str,filesep);
%                         if length(str) < 2
%                             str = path;
%                             break
%                         end
%                         str = fullfile(str{2:end});
%                     end
%                     names{i} = str;
%                 end
             end
            
            self.dlocs = dlocs;
            self.dloc_names = names;
            self.listbox_dlocs.String = self.dloc_names;
        end
        
    end
    
    methods (Access = private)
        
        %         function populate_listbox(self)
        %             self.listbox_dlocs.String = self.dloc_names;
        %         end
    end
    
end

