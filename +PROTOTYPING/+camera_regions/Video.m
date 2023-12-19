classdef Video < handle
    %STACK_DISPLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % GUI handles
        panel
        axes_display
        image_display
        slider_frames
        
    end
    
    properties (Access = private)
%         roi_array
%         roi_array_plot_handles
        video_reader
    end
    
    methods
        function self = Video(varargin)
            p = inputParser;
            p.addOptional('fig',[], ...
                @(x) validateattributes(x,{'matlab.ui.Figure'},{}));
            p.addOptional('panel_limits',[15,13], ...
                @(x) validateattributes(x,{'numeric'},{'numel',2}));
            p.addOptional('panel_units','centimeters', ...
                @(x) begonia.validators.validatestring(x,{'centimeters'}));
            p.parse(varargin{:});
            begonia.util.dump_inputParser_vars_to_caller_workspace(p);
            %% Figure setup
            if isempty(fig)
                create_figure = true;
            else 
                create_figure = false;
            end
            
            if create_figure
                fig = figure;
                fig.Name = 'Video Display';
                fig.NumberTitle = 'off';
                fig.Units = 'centimeter';
            end
            
            %% Panel
            panel = uipanel;
            panel.Parent = fig;
            panel.Units = 'centimeters';
            self.panel = panel;
            
            %% UI components inside the panel
            axes_display = axes();
            axes_display.Parent = panel;
            axes_display.Units = 'centimeters';
            axes_display.Position(1:2) = [1,1];
            axes_display.Position(3:4) = [13,13];
            colormap(axes_display,begonia.colormaps.viridis);
            self.axes_display = axes_display;
            
            
            image_display = imshow([], [0, 1]);
            image_display.Parent = axes_display;
            self.image_display = image_display;
            
            
            slider_frames = uicontrol(panel,'Style','slider');
            slider_frames.Units = 'centimeters';
            slider_frames.Position(1:2) = axes_display.Position(1:2) - [0,1];
            slider_frames.Position(3) = axes_display.Position(3);
            slider_frames.Position(4) = 0.5;
            slider_frames.Callback = @(s,e) self.callback_slider_frames();
            slider_frames.Min = 1;
            slider_frames.Max = 1;
            slider_frames.Value = 1;
            fig.WindowScrollWheelFcn = @(s,e) self.callback_scroll(e);
            self.slider_frames = slider_frames;
            
            
            
            %% Panel and figure size adjustment.
            PROTOTYPING.camera_regions.autosize_container(panel,0.5);
            if create_figure
                begonia.gui_tools.autosize_container(fig,0.5);
                fig.Position(1:2) = [5,5];
                % Enables rescaling.
                set(findall(fig, '-property', 'Units' ), 'Units', 'Normalized')
            end
        end
        
        
        function load_video_reader(self,video_reader)
            frames = video_reader.Duration * video_reader.FrameRate;
            self.slider_frames.Value = 1;
            self.slider_frames.Max = frames;
            self.video_reader = video_reader;
            self.update_image();
        end
        
    end
    
    methods (Access = private)
        function update_image(self)
            if isempty(self.video_reader)
                return
            end
            frame = self.slider_frames.Value;
            current_time = frame/self.video_reader.FrameRate;
            self.video_reader.CurrentTime = current_time;
            im = self.video_reader.readFrame();
            self.image_display.CData = im;
            drawnow;
        end
        
        
        function callback_slider_frames(self)
        end
        
        
        function callback_scroll(self,event)
           
            val = round(self.slider_frames.Value);
            val_max = round(self.slider_frames.Max);
            val_min = round(self.slider_frames.Min);
            val_add = max(1,round(event.VerticalScrollCount));
            val_add = sign(event.VerticalScrollCount)*val_add;
            val = val + val_add;
            val = min(val,val_max);
            val = max(val,val_min);
            self.slider_frames.Value = val;
            
            self.update_image();
        end
    end
    
end


