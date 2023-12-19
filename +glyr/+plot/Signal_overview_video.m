function Signal_overview_video(ts,do_traces,fs)
if nargin < 3, fs = 30; end
if nargin < 2, do_traces = false; end

mtab = ts.load_var('multitab');
pupil = mtab.trace{mtab.category == 'pupil_ratio'};
whisk = mtab.trace{mtab.category == 'whisker'};
speed = mtab.trace{mtab.category == 'speed'};
speed = 8 * 0.017453 * speed; %cm/s

astrocytes = mtab(startsWith(mtab.roi_type,"A"),:);
ast = [astrocytes.trace{:}];
neurons = mtab(startsWith(mtab.roi_type,"N"),:);
neu = [neurons.trace{:}];


ast_types =  unique(astrocytes.roi_type,"stable");
ast_type_start = arrayfun(@(tp) find(astrocytes.roi_type == tp, 1, 'first'), ast_types);

neu_types =  unique(neurons.roi_type,"stable");
neu_type_start = arrayfun(@(tp) find(neurons.roi_type == tp, 1, 'first'), neu_types);

dt = unique(mtab.trace_dt);
entity = unique(mtab.entity);

% create tilelayout
fig = figure("Position",[928,253,1118,979]);
if do_traces    
    layout = tiledlayout(7,1);
    title(layout,"Signal overview " + entity)
    
    % pupil
    ax_pup = nexttile(1);
    pup_plot = plot(ax_pup,pupil);
    xlim tight
    % hold on
    % xline(0,'LineWidth',2,'r')
    title("Pupil-eye ratio")
    xticks(ax_pup, [])
    ylabel('ratio')
   
    % speed
    ax_speed = nexttile(2);
    speed_plot = plot(speed);
    xlim tight
    % hold on
    % xline(0,'LineWidth',2,'r')
    title("Speed")
    xticks(ax_speed, [])
    ylabel('cm/s')
    
    % whisking
    ax_whisk = nexttile(3);
    whisk_plot = plot(whisk);
    xlim tight
    title("Whisking")
    xticks(ax_whisk, []) 
    ylabel('a.u')
else    
    layout = tiledlayout(5,1);
    ax_behav = nexttile();
    glyr.plot.plot_behaviour(ts,false,false)
    delete(ax_behav.Legend)   
end
    
% astrocytes
ax_ast = nexttile([2,1]);
imagesc(ast');
colormap(ax_ast,begonia.colormaps.magma);
colorbar();
caxis([-0.05 2.05])
title("Astrocytes (df/f0)");
yticks(ast_type_start); yticklabels(ast_types);
xticks(ax_ast, [])

% neurons
ax_neu = nexttile([2,1]);
imagesc(neu');
colormap(ax_neu,'parula');
colorbar();
caxis([-0.05 1.05])
title("Neurons (df/f0)"); xlabel("Frame (#)");
colorbar();
yticks(neu_type_start); yticklabels(neu_types);
xlabel("Time (sec)")
axis tight
xticks(300:300:length(neu));
xticklabels(xticks*dt);

ax_line = axes('position', get(ax_neu, 'position'));
if do_traces
    ax_line.Position(4) = ax_pup.Position(2) + 0.020;
else
%     ax_line.Position(4) = 1 - 1.5*ax_behav.Position(4);
 ax_line.Position(4) = ax_behav.Position(2) + 0.020;
end

ax_line.Color = 'none';
ax_line.XLim = ax_neu.XLim;
l = xline(ax_line,0,'r','LineWidth',2);
ax_line.Visible = 'off';


% Make video
filename = sprintf("/Volumes/GlyR/Signal_overview_video/%s",ts.name);
begonia.path.make_dirs(filename);
v = VideoWriter(filename,"MPEG-4");
v.FrameRate = fs;
v.open();
frames = 1:length(ast); % all traces have the same lenght. Does not matter which varibale
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