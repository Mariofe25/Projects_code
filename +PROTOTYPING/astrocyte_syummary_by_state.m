import begonia.logging.log
behav = unique(mtab.seg_category);
behav = string(behav);
for i = 1:length(behav)
    log(1,'Summary plot, FoV with paired behaviour: %s',behav(i))
    glyr.astrocytes_summary_paired_state(mtab,behav(i),1)  
end
log(1,'Done!')