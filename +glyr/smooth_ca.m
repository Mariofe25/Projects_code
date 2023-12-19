function smooth_ca(tss)

for ts = tss
    mtab = ts.load_var('multitab');

    ca_idx = mtab.category == "ca-roi-dff";
    mtab.trace(ca_idx)= cellfun(@(s) sgolayfilt(s,1,21),mtab.trace(ca_idx,:),...
        'UniformOutput',false);

    ts.save_var('multitab',mtab)
end
end