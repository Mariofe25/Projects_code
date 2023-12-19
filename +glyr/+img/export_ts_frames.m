import begonia.logging.log
for ts = trs
    log(1,"Getting frames from " + ts.name)
    ch1 = ts.get_mat(1);
    ch1 = ch1(:,:,:);
    
    ch2 = ts.get_mat(2);
    ch2 = ch2(:,:,:);
    
    path = '/Volumes/GlyR/Tss_IVM';
    folder_name = fullfile(path,ts.name);
    
    
    if do_smooth
        ch1 = movmean(ch1,30,3);
        ch2 = movmean(ch2,30,3);
        folder_name = folder_name + "_smooth/";
    else
        folder_name = folder_name + "/";
    end
    
    begonia.path.make_dirs(folder_name)
    
    ch1 = glyr.img.normalize(ch1,'type','uint8');
    ch2 = glyr.img.normalize(ch2,'type','uint8');
    
    tic
    for i = 1:size(ch1,3)
        if toc > 5 || i == 1 || i == size(ch1,3)
            tic
            log(1,"Writing frame %d/%d (%.f%%)", ...
                i, ...
                size(ch1,3), ...
                i / size(ch1,3) * 100);
        end
        
        filename_ast = fullfile(folder_name,"astrocytes_" + i + ".tif");
        filename_neu = fullfile(folder_name,"neurons_" + i + ".tif");
        imwrite(ch1(:,:,i),filename_ast,'tif')
        imwrite(ch2(:,:,i),filename_neu,'tif')
    end
end