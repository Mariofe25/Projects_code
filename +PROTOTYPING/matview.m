function matview(mat, min_max,change_frame_callback)
% change_frame_callback is a function on the form : img = func(mat,frame)
% that can be used to modify the image shown. 
if nargin < 1
    disp('You need to provide a matrix as the first argument');
    return;
end

if nargin < 2
    min_max = [];
end

if nargin < 3
    change_frame_callback = [];
end

dim = size(mat);

f = figure();
pos = f.Position;
f.Position = [pos(1), pos(2), pos(3)*0.7, pos(4)*0.8];
f.Name = inputname(1);

ax = axes();
ax.Parent = f;
ax.Units = 'Normalized';
ax.Position = [0.05, 0.15, 0.7, 0.8];

slider = uicontrol(f,'Style','slider');
slider.Min = 1;
slider.Max = dim(3);
slider.Value = 1;
slider.Units = 'Normalized';
slider.Position = [0.05, 0.05, 0.7, 0.05];

htext = uicontrol(f,'Style','text');
htext.Units = 'Normalized';
htext.Position = [0.05, 0.1, 0.7, 0.05];
htext.String = '1';

if length(min_max) == 2
    himg = imagesc(mat(:,:,1), min_max);
else
    himg = imagesc(mat(:,:,1));
end

% Try using the turbo colormap if it exists. 
colormap(begonia.colormaps.turbo());

c = colorbar(ax);
c.Position = [0.80, 0.05, 0.05, 0.9];

function change_frame(frame)
    if isempty(change_frame_callback)
        img = mat(:,:,frame);
    else
        img = change_frame_callback(mat,frame);
    end
    himg.CData = img;
    htext.String = num2str(frame);
    if isempty(min_max)
        try
            c.Limits = double([min(img(:)),max(img(:))]);
        end
    end
end

function slider_callback(src, event)
    src.Value = round(src.Value);
    change_frame(src.Value);
end
slider.Callback = @slider_callback;

function scroll_callback(src, event)
    slider.Value = round(slider.Value + event.VerticalScrollCount);
    if slider.Value < slider.Min
        slider.Value = slider.Min;
    elseif slider.Value > slider.Max
        slider.Value = slider.Max;
    end
    change_frame(slider.Value);
end
f.WindowScrollWheelFcn = @scroll_callback;

ax.YTick = [];
ax.XTick = [];
end



