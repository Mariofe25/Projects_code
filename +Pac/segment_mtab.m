function mtab_seg = segment_mtab(tss)
% Segment multitable by behaviour state

% mtab_seg = multitable w/ segmented data.
% Behaviour state: Still,Still-Whisking,Trans.Still-Motion(Run), Motion/Run

import begonia.data_management.multitable.*
import begonia.logging.*

% Load multitable
n = 0;
for ts = tss
    n = n +1;
    backwrite(1,'Segmenting multitable from Entities: %d/%d',n,length(tss))
    mtab = ts.load_var("multitab");

    % Update locomoiton trace with the whisking to add Still-Whisking
    % category to the segmentation
    whisking = mtab.trace{mtab.category == "whisking"};
    locomotion = mtab.trace{mtab.category == "locomotion"};
    locomotion(locomotion == "Still" & whisking) = "Still-Whisking";
    mtab.trace{mtab.category == "locomotion"} = locomotion;

    %% Segment multitab by behaviour state
    % Get Lomotion state trace from each experimental state
    loc =  mtab.trace{mtab.category == "locomotion"};

    % Segment multitable
    mtab_seg = segment_entity(mtab,"locomotion",unique(loc));
    mtab_seg = sortrows(mtab_seg,["category","roi_type","roi_id","seg_start_f"]);

    ts.save_var("multitab_segmented",mtab_seg)
end
log(1,"Segmentation Done!")
end