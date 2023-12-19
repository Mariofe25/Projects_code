VIDEO_OUT = '/Users/mariofernandez/Desktop/trial/test2.mov';
WIN_SIZE = 25;

begonia.path.make_dirs(VIDEO_OUT)

% make data:
data_a = trials{1}.trace{:};
data_b = trials{1}.trace{trials{1}.category == 'wheel'}

% make writer;
vwriter = VideoWriter(VIDEO_OUT, 'MPEG-4');
vwriter.FrameRate = 60;
vwriter.open()

% make a figure to paint frames on:

fig = figure();
ax_a = subplot(2,1,1);
ax_b = subplot(2,1,2);

% create frames for video:
for i = 1:10:length(data_a)

%     imagesc(ax_a,horzcat(data_a{i}))
    plot(ax_a,data_a(1:i))
    plot(ax_b,data_b(1:i))

    xlim(ax_a,[1,length(data_a)]);
    xlim(ax_b,[1,length(data_b)]);
    
    drawnow();
    video_frame = getframe(fig);
    vwriter.writeVideo(video_frame);
    
end

% finish video file:
 vwriter.close();
% delete(fig);

% fig = figure('Position', [100,100,500,400]);
% ax_a = axes(fig);
% setpixelposition(ax_a, [0,0,500,200]);
% ax_b = axes(fig);
% setpixelposition(ax_b, [0,200,500,200]);
% 
% % create frames for video:
% for i = WIN_SIZE:length(data_a) - WIN_SIZE
%     win = i - (WIN_SIZE-1):i + WIN_SIZE;
% 
%     plot(ax_a, win, data_a(win))
%     
%     plot(ax_b,win, data_b(win))
%     
%     xlim(ax_a, [win(1) win(end)]);
%     xlim(ax_b, [win(1) win(end)])
%     
%     %drawnow();
%     video_frame = getframe(fig);
%     vwriter.writeVideo(video_frame);
%     
% end
% 
% % finish video file:
% vwriter.close();
% delete(fig);
