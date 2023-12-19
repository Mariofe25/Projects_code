classdef RoiOverlay < handle
    %ROIOVERLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        axes_display
        image_display
        panel
        popup_regions
        
        button_panel
        regions_of_interest
        % Area marked as roi in pixels.
        brush_radius = 30
        region_names
        alpha = 0.3
    end
    
    properties (Access = private)
        region_image_handles
        brush_handle
        button_down = false
    end
    
    methods
        function self = RoiOverlay(varargin)
            %% Input
            p = inputParser;
            p.addRequired('fig', ...
                @(x) validateattributes(x,{'matlab.ui.Figure'},{}));
            p.addRequired('axes_display', ...
                @(x) validateattributes(x,{'matlab.graphics.axis.Axes'},{}));
            p.addOptional('region_names',{'whiskers','wheel','breath'}, ...
                @(x) validateattributes(x,{'cell'},{}));
            p.addOptional('panel_limits',[5,15], ...
                @(x) validateattributes(x,{'numeric'},{'numel',2}));
            p.addOptional('panel_units','centimeters', ...
                @(x) begonia.validators.validatestring(x,{'centimeters'}));
            p.parse(varargin{:});
            begonia.util.dump_inputParser_vars_to_caller_workspace(p);
            
            self.axes_display = axes_display;
            self.region_names = region_names;
            %% Panel
            panel = uipanel;
            panel.Parent = fig;
            panel.Units = 'centimeters';
            panel.Position(3:4) = panel_limits;
            self.panel = panel;
            %% Button Panel
            button_panel = PROTOTYPING.camera_regions.ButtonPanel(panel);
            self.button_panel = button_panel;
            
            %% Other ui elements
            popup_regions = uicontrol('Style', 'popupmenu');
            popup_regions.String = region_names;
            self.popup_regions = popup_regions;
            button_panel.add_graphics_object(popup_regions);
            
            %% Mouse move callback.
            fig.WindowButtonMotionFcn = @(s,e) self.on_mouse_move();
            fig.WindowButtonDownFcn = @(s,e) self.on_button_down();
            fig.WindowButtonUpFcn = @(s,e) self.on_button_up();
            
        end
        
        
        function save_regions(self,dloc)
            if isempty(dloc); return; end
            fprintf('Saving regions to    : %s\n',dloc.path);
            dloc.save_var('video_region_names',self.region_names);
            dloc.save_var('video_region_mask',self.regions_of_interest);
        end
        
        
        function load_regions(self,dloc)
            if isempty(dloc); return; end
            regions_of_interest = dloc.load_var('video_region_mask',[]);  %#ok<*PROPLC>
            
            % check the array loaded matched out expectations. This can be
            % off if the types of video rois changed:
            if ~isequal(size(regions_of_interest),size(self.regions_of_interest))

                % attempt to extend the array in the depth axis and retain
                % old values:
                warning("RoiOverlay: size of regions of interest not equal" ...
                    + "Presuming video roi class added and cells, saving old regions " ...
                    + "extending array depth");
                
                w = size(regions_of_interest, 1);
                h = size(regions_of_interest, 2);
                dold = size(regions_of_interest,3);
                dnew = size(self.regions_of_interest,3);
                new_regs = false(w,h,dnew);
                new_regs(:,:,1:dold) = regions_of_interest;
                
                % check it's ok now, if so use it + backup old values:
                if isequal(size(new_regs),size(self.regions_of_interest))
                    dloc.save_var('video_region_mask_back', regions_of_interest);
                    regions_of_interest = new_regs;
                else
                    error("Could not load the video rois, nor extend the existing rois to match size");
                end
            end
            
            self.regions_of_interest = regions_of_interest;
            self.update_overlay();
        end
        
        
        function clear_regions(self,dloc)
            if isempty(dloc); return; end
            fprintf('Clearing regions off : %s\n',dloc.path);
            dloc.clear_var('video_region_names');
            dloc.clear_var('video_region_mask');
            self.load_ui_image(self.image_display);
        end
        
        
        function load_ui_image(self,image)
            self.image_display = image;
            dim = size(image.CData);
            dim_image = dim(1:2);
            dim_image_color = [dim(1:2),3];
            %% Callback for when the user presses the image.
            image.ButtonDownFcn = @(s,e) self.click_image(e.IntersectionPoint);
            %% Reset regions of interest.
            self.regions_of_interest = zeros([dim_image,length(self.region_names)],'logical');
            
            %% Delete old image handles
            for i = 1:length(self.region_image_handles)
                if isvalid(self.region_image_handles(i))
                    delete(self.region_image_handles(i));
                end
            end
            self.region_image_handles = gobjects(0);
            
            %% Init roi overlay image handles
            axes(self.axes_display)
            hold on
            for i = 1:length(self.region_names)
                self.region_image_handles(i) = imshow(zeros(dim_image_color));
                self.region_image_handles(i).HitTest = 'off';
                self.region_image_handles(i).PickableParts = 'none';
                self.region_image_handles(i).AlphaData = zeros(dim_image);
            end
            hold off
        end
        
        
        function update_overlay(self)
            if isempty(self.regions_of_interest); return; end
            dim = size(self.regions_of_interest);
            dim_image = dim(1:2);
            dim_image_color = [dim(1:2),3];
            color = begonia.util.distinguishable_colors(length(self.region_names));
            for i = 1:length(self.region_names)
                mask = self.regions_of_interest(:,:,i);
                img = zeros(dim_image_color);
                img(:,:,1) = mask*color(i,1);
                img(:,:,2) = mask*color(i,2);
                img(:,:,3) = mask*color(i,3);
                self.region_image_handles(i).CData = img;
                self.region_image_handles(i).AlphaData = mask*self.alpha;
                uistack(self.region_image_handles(i),'top');
            end
        end
        
        
        function click_image(self,xy)
            if PROTOTYPING.camera_regions.time_since_last_call() < 50
                return
            end
            assert(...
                size(self.regions_of_interest,1) == size(self.image_display.CData,1) && ...
                size(self.regions_of_interest,2) == size(self.image_display.CData,2), ...
                'Image has not been loaded.')
            xy = round(xy);
            r = round(self.brush_radius);
            side = round(r);
            [i,j] = meshgrid(-side:side,-side:side);
            mat = i.*i + j.*j <= r*r;
            x1 = xy(1) - r;
            x2 = xy(1) + r;
            y1 = xy(2) - r;
            y2 = xy(2) + r;
            
%             max_y  = size(self.image_display.CData,1);
%             max_x  = size(self.image_display.CData,2);
%             
%             x1 = max(x1,1);
%             x1 = min(x1,max_x);
%             x2 = max(x2,1);
%             x2 = min(x2,max_x);
%             y1 = max(y1,1);
%             y1 = min(y1,max_x);
%             y2 = max(y2,1);
%             y2 = min(y2,max_y);
            
            chosen_region = self.popup_regions.Value;
            try
            self.regions_of_interest(y1:y2,x1:x2,chosen_region) = mat | self.regions_of_interest(y1:y2,x1:x2,chosen_region);
            end
            self.update_overlay();
        end
    end
    
    methods (Access = private)
        
        function on_button_down(self) 
            self.button_down = true; 
        end
        
        
        function on_button_up(self)
            self.button_down = false;
        end
        

        function on_mouse_move(self)
            if isempty(self.image_display)
                return;
            end
            %% Coordinates
            xy = self.axes_display.CurrentPoint([1,4]);
            xy = round(xy);
            
            max_y  = size(self.image_display.CData,1);
            max_x  = size(self.image_display.CData,2);
            if xy(1) < 0 || xy(1) > max_x
                return
            end
            if xy(2) < 0 || xy(2) > max_y
                return
            end
            %% Update brush outline
            th = 0:pi/50:2*pi;
            xdata = self.brush_radius * cos(th) + xy(1);
            ydata = self.brush_radius * sin(th) + xy(2);
            del = (xdata < 0) | (xdata > max_x) | (ydata < 0) | (ydata > max_y);
            xdata(del) = [];
            ydata(del) = [];
            
            if isempty(self.brush_handle)
                hold(self.axes_display,'on')
                self.brush_handle = plot(self.axes_display,xdata,ydata,'yellow');
                hold(self.axes_display,'off');
                self.brush_handle.HitTest = 'off';
                self.brush_handle.PickableParts = 'none';
            else
                self.brush_handle.XData = xdata;
                self.brush_handle.YData = ydata;
            end
            %% Click if mouse down
            if self.button_down
                self.click_image(xy)
            end
            
        end
    end
    
end

