import begonia.logging.log
behav = unique(mtab.seg_category);
behav = string(behav);
for i = 1:length(behav)
    log(1,'Summary plot, FoV with unpaired behaviour: %s',behav(i))
    glyr.plot_summary_unpaired_state(mtab,"neurons",behav(i),1,[]);  
    glyr.plot_summary_unpaired_state(mtab,"astrocytes",behav(i),1,[]);  
end
log(1,'Done!')

