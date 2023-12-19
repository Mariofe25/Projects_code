% take all segments depending on the behavior. e.g. when motion is taken,
% all motion segments, no matter if it is followed or contains a run
% segment, are included
begonia.logging.set_level(1)
method = "segs";

% get mtab with segments minimum 3 sec long
mtab = glyr.mtab_merge_states(tss,0,1,3);
mtab(mtab.category == "spikes_prob",:) = [];

% Pair segments by fov
glyr.rMI(mtab,0,0,method,4,5,"all",0,[],[],1,1)
glyr.rMI_by_sec(mtab,0,"Run",0)
glyr.rMI_by_sec(mtab,0,"Motion",0)


% % Pair segments by entity
% glyr.rMI_by_sec(mtab,1,"Run",0)
% glyr.rMI_by_sec(mtab,1,"Motion",0)
% glyr.rMI(mtab,1,0,0,4,5,"all",0,[],[],1,1)

%%  MI with run and motion combined (Locomotion)
% get mtab with no minimum segment length filtering. So that if segments 
% are combined and longer than 3sec, these are not removed. 
mtab = glyr.mtab_merge_states(tss,0,0);
mtab(mtab.category == "spikes_prob",:) = [];

% Combine motion/run, mo matter the inside segments length or position
% Pair segments by fov
glyr.rMI_by_sec(mtab,0,"Locomotion",0) % by seconds
glyr.rMI(mtab,0,1,method,4,5,"all",0,[],[],1,1) % MI by roi type

% % Pair segments by entity
% glyr.rMI_by_sec(mtab,1,"Locomotion",0)
% glyr.rMI(mtab,1,1,method,4,5,"all",0,[],[],1,1)

% take segments depending on the behavior and their exclusivity. e.g. for
% motion segments only pure motion segments are included. This means, that
% motion segments that are followed anad/or contains run periods are not
% taken

% pure/no combined
% glyr.rMI(mtab,0,1,method,4,5,"all",1,"Motion","no_comb",1,1)
% glyr.rMI(mtab,0,1,method,4,5,"all",1,"Run","no_comb",1,1)
% glyr.rMI_by_sec(mtab,0,"Locomotion",1,"Motion")
% glyr.rMI_by_sec(mtab,0,"Locomotion",1,"Run")

% take segments depending on the behavior and their exclusivity. e.g take
% only motion segments that are followed/preceded by a run segment

% % before/start
% glyr.rMI(mtab,0,1,0,4,5,"all",1,"Motion","before",1,1)
% 
% % after/post
% glyr.rMI(mtab,0,1,0,4,5,"all",1,"Motion","after",1,1)