r = 0;
for ts = tss
    r = r+1;
    m = ts.load_var('multitab');
    e = [m.events{:}];
    l = length(e);
    
    
    mm = ts.load_var('multitab_segmented');
    ee = [mm.events{:}];
    ll = length(ee);
        
    n_evs(r,:) = [l,ll]; 
end