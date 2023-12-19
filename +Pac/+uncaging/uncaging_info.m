function shot =  uncaging_info(tss)
for ts = tss
    shot = Pac.get_shotspot(ts);
    Time = Pac.get_shottime(ts);
    shot.Start = Time.start;
    shot.End = Time.end;
    ts.save_var("Uncaging_info",shot)
end
end