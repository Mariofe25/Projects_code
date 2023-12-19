classdef VideoGui < handle
    %VIDEOGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gui_trials
        gui_video
        gui_roi_overlay
        roi_copy
        
        pushbutton_save
        pushbutton_clear
        current_trial
        pushbutton_copy
        pushbutton_paste
        label_roicontrol
        uislide_roi
        radius
    end
    
    methods
        function self = VideoGui(video_regions)
            if nargin < 1
                video_regions = {'whisker','wheel','breath','laser'};
            end
            
            fig = figure();
            xylobium.shared.layout.remove_tools(fig)
            fig.Units = 'centimeters';
            
            %% Get ui components
            gui_trials = PROTOTYPING.camera_regions.DataLocationList(fig,'drawbuttons', 0);
            
            
            
            self.gui_trials = gui_trials;
            
            gui_video = PROTOTYPING.camera_regions.Video(fig);
            
            self.gui_video = gui_video;
            
            gui_roi_overlay = PROTOTYPING.camera_regions.RoiOverlay(fig,gui_video.axes_display,video_regions);
            self.gui_roi_overlay = gui_roi_overlay;
            
            %% Position gui elements.
            gui_trials.listbox_dlocs.Position(1:2) = [0,0];
            
            %             gui_trials.panel.Position(1) = gui_trials.listbox_dlocs.Position(1) ...
            %                 + gui_trials.listbox_dlocs.Position(3) + 1;
            
            gui_video.panel.Position =  [gui_trials.listbox_dlocs.Position(1)+gui_trials.listbox_dlocs.Position(3), 0, gui_trials.listbox_dlocs.Position(3)*3, gui_trials.listbox_dlocs.Position(4)];
            
            
            gui_roi_overlay.panel.Position = [ gui_video.panel.Position(1)+gui_video.panel.Position(3), 0, gui_trials.listbox_dlocs.Position(3), gui_trials.listbox_dlocs.Position(4)];
            
            %% New ui elements
            pushbutton_save = uicontrol('Style', 'pushbutton');
            pushbutton_save.String = 'Save regions';
            pushbutton_save.Callback = @(s,e) self.on_save_trial();
            self.pushbutton_save = pushbutton_save;
            gui_roi_overlay.button_panel.add_graphics_object(pushbutton_save);
            
            
            pushbutton_clear = uicontrol('Style','pushbutton');
            pushbutton_clear.String = 'Clear regions';
            pushbutton_clear.Callback = @(s,e) self.on_clear_trial();
            self.pushbutton_clear = pushbutton_clear;
            gui_roi_overlay.button_panel.add_graphics_object(pushbutton_clear);
            
            pushbutton_copy = uicontrol('Style','pushbutton');
            pushbutton_copy.String = 'Copy regions';
            pushbutton_copy.Callback = @(s,e) self.copy_rois();
            self.pushbutton_copy = pushbutton_copy;
            gui_roi_overlay.button_panel.add_graphics_object(pushbutton_copy);
            
            pushbutton_paste = uicontrol('Style','pushbutton');
            pushbutton_paste.String = 'Paste regions';
            pushbutton_paste.Callback = @(s,e) self.paste_rois();
            self.pushbutton_paste = pushbutton_paste;
            gui_roi_overlay.button_panel.add_graphics_object(pushbutton_paste);
            
            
            label_roicontrol = uicontrol('Style','text','String','Roi size');
            self.label_roicontrol = label_roicontrol;
            gui_roi_overlay.button_panel.add_graphics_object(label_roicontrol);         
            
            
            uislide_roi = uicontrol('Style','slider');
            uislide_roi.String = 'Roi size';
            uislide_roi.Max = 50;
            uislide_roi.Min = 10;
            uislide_roi.Value = 30;
            uislide_roi.SliderStep = [0.1 0.2];
            addlistener(uislide_roi,'Value','PostSet', @(s,e) self.roi_size());
            self.uislide_roi = uislide_roi;
            gui_roi_overlay.button_panel.add_graphics_object(uislide_roi);
            uislide_roi.Position = label_roicontrol.Position - [0 0.5 0 0];
            
            radius = uicontrol('Style','text');
            radius.String = '30';
            radius.HorizontalAlignment= 'center';
            self.radius = radius;
            gui_roi_overlay.button_panel.add_graphics_object(radius)
            radius.Position = uislide_roi.Position - [0 0.5 0 0];
            
            %% New callbacks / functionality
            
            gui_trials.listbox_dlocs.addlistener('Value','PostSet',@(s,e) self.on_listbox_value_changed());
            
            %% Adjust figure dimensions.
            %delete(gui_trials.button_panel.panel)
            %self.gui_trials.button_panel = [];
            PROTOTYPING.camera_regions.autosize_container(fig);
            
            fig.Position(1:2) = [10,10];
            set(findall(fig, '-property', 'Units' ), 'Units', 'Normalized')
            fig.Position = [0.1, 0.1, 0.8, 0.8];
            
        end
        
        function paste_rois(self, src, event)
            self.gui_roi_overlay.regions_of_interest = self.roi_copy;
            
            
            self.on_save_trial;
            val = self.gui_trials.listbox_dlocs.Value(1);
            trial = self.gui_trials.dlocs(val);
            im = self.gui_video.image_display;
            self.gui_roi_overlay.load_ui_image(im);
            self.gui_roi_overlay.load_regions(trial);
            
        end
        
        function copy_rois(self, src, event)
            self.roi_copy = self.gui_roi_overlay.regions_of_interest;
            
        end
        
        function load_trials(self,trials)
            self.gui_trials.load(trials);
            self.on_listbox_value_changed();
        end
        
        function roi_size(self, src, event)
            self.radius.String = num2mstr(self.uislide_roi.Value);
            self.gui_roi_overlay.brush_radius = self.uislide_roi.Value;           
        end
    end
    
    
    methods (Access = private)
        
        function on_save_trial(self)
            self.gui_roi_overlay.save_regions(self.current_trial);
        end
        
        
        function on_clear_trial(self)
            self.gui_roi_overlay.clear_regions(self.current_trial);
        end
        
        
        function on_listbox_value_changed(self)
            %% Get the trial
            val = self.gui_trials.listbox_dlocs.Value(1);
            trial = self.gui_trials.dlocs(val);
            self.current_trial = trial;
            %% Get camera file.
            camera_filename = 'camera.avi';
            [files_full,files] = begonia.path.find_files(trial.path, camera_filename);
            if isempty(files)
                error('camera.avi not found');
            end
            I = strcmp(files,camera_filename);
            file = files_full(I);
            assert(length(file) == 1, ' Multiple "camera.avi" found.')
            file = file{1};
            warning off
            video_reader = VideoReader(file);
            warning on
            %% Load new video
            self.gui_video.load_video_reader(video_reader);
            
            %% Load the new image and trial into the overlay
            im = self.gui_video.image_display;
            self.gui_roi_overlay.load_ui_image(im);
            self.gui_roi_overlay.load_regions(trial);
            
        end
    end
    
end

