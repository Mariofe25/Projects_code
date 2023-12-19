tss_path = '/Volumes/Xiaoyi1/PAC/tseries/no-uncaging/ip3r2ko_pac_ctrl';
if isfolder(tss_path)
    tss = begonia.scantype.find_scans(tss_path);
else
    error("NOOOOOOOOOO")
end
begonia.logging.set_level(1)
