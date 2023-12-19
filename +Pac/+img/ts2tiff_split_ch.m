function ts2tiff_split_ch(tss)
for ts = tss
    begonia.logging.log(1,"Splitting " + ts.name + " channels in 2 Tiff files")
    for ch = 1:ts.channels
        out = [ts.path,'_',ts.channel_names{ch},'.tif'];
        Pac.img.tseries_to_tiff(ts,out,ch)
    end
end
end