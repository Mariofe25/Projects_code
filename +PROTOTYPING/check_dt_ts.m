function delta_time =  check_dt_ts(ts)

t = ts.Time;
for i = 1:ts.TimeInfo.Length - 1    
    dts(i) = t(i+1) - t(i);        
end
dts = dts';
dts(1)= [];
u = unique((round(dts,3)),"stable");
n_dts = length(u);
fps = 1./u;

delta_time = struct;
delta_time.Time = t;
delta_time.dt_diff = dts;
delta_time.fps = fps;

if length(n_dts) == 1
    disp("dt is uniform. Fps =  " + fps)
    delta_time.dt = u;
else
    delta_time.min_dt = min(u);
    delta_time.mean_dt = mean(u);
    delta_time.max_dt = max(u);
    disp("dt is not uniform ")
end