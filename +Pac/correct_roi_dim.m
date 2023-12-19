function correct_roi_dim(tss)
for ts = tss
    mat_dim = ts.img_dim;
    roitab = ts.load_var('roi_table');

    rois_dim = cell2mat(cellfun(@(s) size(s), roitab.mask, 'UniformOutput',false));
    disp(ts.name)
    if all(rois_dim == mat_dim)
        disp(" All rois OK")
        continue
    else
        idx = find(rois_dim(:,1) ~= mat_dim(:,1));

        disp(length(idx) + " rois with wrong mask dimesion order.Inverting...")

        for i = 1:length(idx)
            p = false(mat_dim(1),mat_dim(2));
            mask = roitab.mask{idx(i)};

            fx = find(sum(mask, 1) > 0, 1, 'first');
            fy = find(sum(mask, 2) > 0, 1, 'first');
            tx = find(sum(mask, 1) > 0, 1, 'last');
            ty = find(sum(mask, 2) > 0, 1, 'last');

            p(fy:ty, fx:tx) = mask(fy:ty, fx:tx);

            roitab.mask{idx(i)} = p;
        end
        ts.save_var('roi_table', roitab)
    end
end
disp("Done!")
end
