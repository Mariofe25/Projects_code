function Signal_overview_video_v2(ts,fs)
if nargin < 2, fs = 30; end

fig = glyr.plot.plot_activity_rois_by_type(ts,0,'-dnpg',1);

ax_np = fig.Children(2).Children(2);
ax_behav = fig.Children(2).Children(end-1);
delete(fig.Children(2).Children(end));
ax_line = axes('position', get(ax_np, 'position'));
ax_line.Position(4) = 0.85;
ax_line.Color = 'none';
ax_line.XLim = ax_np.XLim;
l = xline(ax_line,0,'r','LineWidth',2);
ax_line.Visible = 'off';

% Make video
filename = sprintf("/Volumes/GlyR/Signal_overview_video_v2/%s",ts.name);
begonia.path.make_dirs(filename);
v = VideoWriter(filename,"MPEG-4");
v.FrameRate = fs;
v.open();
mtab = ts.load_var('multitab');
ln = unique(cellfun(@length,mtab.trace));
frames = 1:ln; 
tic
for frame = frames
    if toc > 1
        begonia.logging.log(1,"%d/%d",frame,frames(end));
        tic
    end
    
    % time mark
    l.Value = frame;
    v.writeVideo(getframe(fig));
end

v.close();
disp("Done!")
close(fig);
end