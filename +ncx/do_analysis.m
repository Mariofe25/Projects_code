function do_analysis(tss,threshold)
if nargin < 2
    error("threshold method should be: 'median','2std','3std' or 'all'")
end
if threshold == "all"
    threshold = ["median","2std","3std"];
end

for th = threshold
    ncx.ca_latency(tss,true,true,th)
    ncx.summary_latency(tss,true,th)
    path ='/Users/mariofernandez/Downloads/jarand-copy/analysis/latency';
    ncx.responsiveness(path,th)
end
end