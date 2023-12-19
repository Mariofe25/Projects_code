speed = mtab.trace{mtab.category == "speed"};

  
  
dt = 0.0333;
x=[dt:dt:length(speed)* dt];
fig = figure;
Dx=100;
p = plot(x,speed);
filename = sprintf("/Volumes/GlyR/Signal_overview_video_v4/%s",ts.name);
begonia.path.make_dirs(filename);
v = VideoWriter(filename,"MPEG-4");
v.FrameRate = 30;
v.open();
p.Parent.Box = 'off';
p.Parent.YLim = [-20 140];
p.Parent.YAxis.LimitsMode = "manual";
p.Parent.XLim = [-x(Dx) 0];
for n= 1:1:numel(x)
    p.Parent.XLim = p.Parent.XLim + 0.0333;
    v.writeVideo(getframe(fig)); drawnow
end
v.close
close(fig)
