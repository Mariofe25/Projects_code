import begonia.logging.log
begonia.logging.set_level(1)
denoise_path = uigetdir;
for ts = tss
    Pac.img.combine_ch_tstiff(ts,denoise_path)
end
log(1,"Denoised channel combined!")