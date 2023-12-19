import begonia.logging.log
behav = unique(mtab.seg_category);
behav = string(behav);
for i = 1:length(behav)
    log(1,'Summary spikes probability, FoV with unpaired behaviour: %s',behav(i))
    glyr.spikes_unpaired_state(mtab,behav(i),1,[]);  
end
log(1,'Done!')


