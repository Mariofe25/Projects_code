function camera_regions = read(trial)
%%
files = begonia.path.find_files(trial.Path, 'camera.avi');
assert(~isempty(files), ' "camera.avi" not found.');
assert(length(files) == 1, ' Multiple "camera.avi" found.')
file = files{1};
warning('off')
vidObj = VideoReader(file);
warning('on')
%%

files = begonia.path.find_files(trial.Path,'camera_time.csv');
assert(~isempty(files), 'camera_time.csv not found.');
assert(length(files) == 1, 'Multiple camera_time.csv found.');

mat = dlmread(files{1}, ',', 22, 1);
camera_t = mat(:,1)/1000;
%%
video_region_names = trial.load_var('video_region_names');
video_region_mask = trial.load_var('video_region_mask');

num_regions = size(video_region_mask,3);
%%
str = sprintf('Reading camera with %d frames: %s\n',vidObj.FrameRate*vidObj.Duration,trial.Path);
begonia.logging.log(1,str);
%%
camera = zeros(0,num_regions);
% Read rgb
im_pre = vidObj.readFrame();
% To grayscale
im_pre = mean(im_pre,3);

i = 1;
while vidObj.hasFrame
    % Read rgb
    im = vidObj.readFrame();
    % To grayscale
    im = mean(im,3);
    
    im_1 = abs(im - im_pre);
    for j = 1:num_regions
        im_2 = video_region_mask(:,:,j);
        camera(i,j) = sum(im_1(:).*im_2(:))/sum(im_2(:));
    end
    
    im_pre = im;
    
    i = i + 1;
end
%%
camera_t = reshape(camera_t,[],1);
camera_t(end) = [];
camera_t = camera_t - camera_t(1);
if length(camera) > length(camera_t)
    camera = camera(1:length(camera_t),:);
elseif length(camera_t) > length(camera)
    camera_t = camera_t(1:length(camera));
end

for i = 1:num_regions
    
    cam = timeseries(camera(:,i),camera_t,'Name',video_region_names{i});
    cam = cam.resample(linspace(camera_t(1),camera_t(end),cam.Length));
    cam = cam.setuniformtime('Interval',cam.Time(2)-cam.Time(1));
    cams{i} = cam;
end

camera_regions = tscollection(cams, 'Name', 'Camera with regions');


end

