function ts2tif_split_ch(ts)
for ch = 1:ts.channels
    out = [ts.path,'_',ts.channel_names{ch},'.tif'];
    Pac.tseries_to_tiff(ts,out,ch)
end
end