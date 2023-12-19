function gdata = init(dcat_path, data_path)
    import begonia.data_management.*;
    dcat = yucca.datacat.DataCat();
    dcat.connect(dcat_path);
    
    stash_path = fullfile(data_path, "Stash");
    mtab_path = fullfile(data_path, "Mtab");
    
    stash = Stash(stash_path);
    mtab = Megatable(mtab_path, stash, 1/30);
    
    % collect data:
    gdata = struct;
    gdata.dcat = dcat;
    gdata.mtab = mtab;
    gdata.stash = stash;
    
end


