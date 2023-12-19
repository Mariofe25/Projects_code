import begonia.logging.log
behav = unique(mtab.seg_category);
behav = string(behav);
for i = 1:length(behav)
    log(1,'Events features summary plot: %s',behav(i))
    glyr.plot_event_features_unpaired(mtab,"neurons",behav(i),1,[]);  
    glyr.plot_event_features_unpaired(mtab,"astrocytes",behav(i),1,[]);  
end
log(1,'Done!')






