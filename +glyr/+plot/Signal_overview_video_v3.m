function Signal_overview_video_v3(ts,fs)

 fig = glyr.plot.plot_activity_rois_by_type(ts,0,'-dnpg',1);

% find axes (tiles)
tiles = findobj(fig.Children,'type','tiledlayout');
tile_axs = findobj(tiles,'type','axes');

% get behaviour plot
idx_behav = contains(string(arrayfun(@(s) s.Title.String,tile_axs,...
    'UniformOutput',false)),"Behaviour");
ax_behav = tile_axs(idx_behav);
ax_behav.XLimMode = 'manual';

% heatmaps axes
axs_h = tile_axs(~idx_behav);
% data_h = arrayfun(@(s) s.Children.CData,axs_h,'UniformOutput',false);

% delete(fig.Children(2).Children(end))

% create a rectangule that cover the behav plot and shrinks each frame
for i = 1:length(axs_h)
    xx = axs_h(i).XLim;
    yy = axs_h(i).YLim;
    pos = [xx(1),yy(1), xx(2), yy(2)];
    rr(i) = rectangle(axs_h(i), ...
        'Position', pos, ...
        'FaceColor', fig.Color, ...
        'EdgeColor', 'none');
end

xx = ax_behav.XLim;
yy = ax_behav.YLim;
pos = [xx(1),yy(1), xx(2), yy(2) + 0.5*yy(2)];
r = rectangle(ax_behav, ...
    'Position', pos, ...
    'FaceColor', fig.Color, ...
    'EdgeColor', 'none');

% video
filename = sprintf("/Volumes/GlyR/Signal_overview_video_v3/%s",ts.name);
begonia.path.make_dirs(filename);
v = VideoWriter(filename,"MPEG-4");
v.FrameRate = 30;
v.open();

mtab = ts.load_var('multitab');
ln = unique(cellfun(@length,mtab.trace));
frames = 1:ln; 
dt = unique(mtab.trace_dt);
tic
for frame = frames
   
    if toc > 1
        begonia.logging.log(1,"%d/%d",frame,frames(end));
        tic
    end

    pos(1) = pos(1) + dt;
    pos(3) =  pos(3) - dt;
    r.Position = pos;
   
    for j = 1:length(rr)
        rr(j).Position = rr(j).Position + [1 0 -1 0];
    end
    
    v.writeVideo(getframe(fig));
    
end
v.close
disp("Done!")
close(fig);
end
