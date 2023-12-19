function move2mtab(gdata,tss,mo) 

glyr.img.rois_to_mtab(gdata,tss,mo)
glyr.rig.wheel.wheel_to_mtab(gdata,tss)
glyr.rig.pupil.pupil_to_mtab(gdata,tss)
glyr.whisker.whisking_to_mtab(gdata,tss)
glyr.whisker.whisklog_to_mtab(gdata,tss)

end