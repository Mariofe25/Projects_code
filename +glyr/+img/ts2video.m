function [mat,mat2] = ts2video (ts,output_path,do_smooth,window_size,ColorChannel,do_merge,n_frames,fps)

% Convert 1 or 2(max) channel tseries to video (avi format). Frame rate is
% the sme as in the recording

% Output:
%   mat/mat2 =  channel arrays

% Input:
%   ts = tseries(TSeries obj)
%   output_path = dir where video is saved
%   do_smooth = apply moving average of n frames when true(default)
%   window_size = n frames for movmean. It can be the same for both channels 
%                 (i.e 30) or specific for each channel (i.e.[10 5])
%   ColorChannel = if not merge, channel can be red/green('Original') or
%                  use a colormap(default)
%   do_merge = merge channels. Red/green

% ie.
% Create a video with separate channels in green/red and with frame average
% of 30 frames for ch1 and 10 frames for ch2.
% glyr.img.ts2video(tss(1),output_path,true,[30 10],'Original');

% Create a video with merged channels in green/red with no frame average
% glyr.img.ts2video(tss(1),output_path,false,[],[],true);

if nargin < 8
    fps = round(1/ts.dt);
end

if nargin < 7 || isempty(n_frames)
    n_frames = [1:ts.frame_count];
end

if nargin < 6
    do_merge = false;
end

if nargin < 5 || isempty(ColorChannel)
    ColorChannel = 'Default';
end

if nargin < 4 || isempty(window_size)
    window_size = 10;
end

if nargin < 3 || isempty(do_smooth)
    do_smooth = true;
end

if nargin < 2 || isempty(output_path)
    output_path = uigetdir;
end

path = fullfile(output_path,ts.name);

% get tseries channel frames
ch1 = ts.get_mat(1,1);
ch1 = ch1(:,:,n_frames);
if ts.channels >= 2
    ch2 = ts.get_mat(2,1);
    ch2 = ch2(:,:,n_frames);
end

% smooth frames

if do_smooth
    if length(window_size) == 2
        ch1 = movmean(ch1, window_size(1),3);
    else
        ch1 = movmean(ch1, window_size,3);
    end
    try        
        if length(window_size) == 2
            ch2 = movmean(ch2,window_size(2),3);
        else
            ch2 = movmean(ch2,window_size,3);
        end
    catch
    end
end

% normalize and convert to uint8.
ch1 = glyr.img.normalize(ch1,'type','uint8');
if ts.channels >= 2
    ch2 = glyr.img.normalize(ch2,'type','uint8');
    mat2 = zeros([size(ch2,[1,2]),3,size(ch2,3)],'uint8');
end

mat = zeros([size(ch1,[1,2]),3,size(ch1,3)],'uint8');
if do_merge
    % Color channels (red, green)
    for i = 1: size(ch1,3)
        mat(:,:,:,i) = imfuse(ch1(:,:,i),ch2(:,:,i),'falsecolor','ColorChannel',[1 2 0]);
    end
    type = 'MPEG-4';
%      type = 'Uncompressed AVI';
else
    switch ColorChannel
        case 'Original'
            z = zeros(size(ch1(:,:,1)));
            if ts.channels >= 2
                zz = zeros(size(ch2(:,:,1)));
            end
            for i = 1:length(n_frames)            
                mat(:,:,:,i) = cast(cat(4,z,imadjust(ch1(:,:,i)), z), class(ch1));
                if ts.channels == 2
                    mat2(:,:,:,i) = cast(cat(4,imadjust(ch2(:,:,i)),zz, zz), class(ch2));
                end
            end
             type = 'MPEG-4';
%             type = 'Uncompressed AVI';
            if ts.channels >= 2
                mat = horzcat(mat,mat2);
            end
            
        case 'Default'
            map = begonia.colormaps.viridis(256);
            type = 'Indexed AVI';
            mat = horzcat(ch1,ch2);
    end
end

% Write video
v = VideoWriter(path,type);
if type == "Indexed AVI"
    v.Colormap = map;
end
v.FrameRate =  fps;
open(v);
writeVideo(v,mat);
close(v)

end