tss_path = '/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/Denoised_Ip3r2ko';
if isfolder(tss_path)
    tss = begonia.scantype.find_scans(tss_path);
else
    error("NO GOD!PLEASE NO!!NOOOOOOOOO")
end
begonia.logging.set_level(1)
