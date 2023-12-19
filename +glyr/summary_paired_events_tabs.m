import begonia.logging.log
behav = unique(mtab.seg_category);
behav = string(behav);
for i = 1:length(behav)
    log(1,'Summary table, FoV with paired behaviour: %s',behav(i))
    glyr.tab_summary_paired_state(mtab,"neurons",behav(i),1,[]);  
    glyr.tab_summary_paired_state(mtab,"astrocytes",behav(i),1,[]);  
end
log(1,'Done!')



