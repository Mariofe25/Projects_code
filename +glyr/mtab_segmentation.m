function mtab_seg = mtab_segmentation(tss)
% Segment multitable by experimental state & behaviour state

% mtab_seg = multitable w/ segmented data. It adds 3 columns indicating
% the experimental category and state  and the behaviour state.

% Experimental category: w/ IVM and w/o IVM
% Experimental state: Baseline, Stimulation & Post-Stimulation
% Behaviour state: Still,Still-Whisking,Trans.Still-Motion(Run), Motion/Run
%                  Trans.Motion(Run)-Still

import begonia.data_management.multitable.timerange
import begonia.data_management.multitable.*
import begonia.logging.log;

% Load multitable
for ts = tss
    log(1,"Creating/Saving segmented multitable for " + ts.name)
    mtab = ts.load_var("multitab");
    if contains(ts.path,"post")
        exp_cat = "postIVM";
    elseif contains(ts.path,"IVM")
        exp_cat = "IVM";
    else
        exp_cat = "noIVM";
    end

%     % Recalculate df/f for MI
%     ca_idx = mtab.category == "ca-roi-dff";
%     for i = 1:sum(ca_idx)
%         trace = mtab.trace{i};
%         trace = trace*100 + 100;
%         df  = trace/100;
%         mtab.trace{i} = df;
%     end


    % Update locomoiton trace with the whisking to add Still-Whisking
    % category to the segmentation
    whisking = mtab.trace{mtab.category == "whisking"};
    locomotion = mtab.trace{mtab.category == "locomotion"};
    locomotion(locomotion == "Still" & whisking) = "Still-Whisking";
    mtab.trace{mtab.category == "locomotion"} = locomotion;

    % Split traces by experimental state
    exp = mtab.trace{mtab.category == "exp_state"};

    b = find(exp == "Baseline");
    s = find(exp == "Stim");
    p = find(exp == "Post");


    fps = 1/unique(mtab.trace_dt);
    baseline = timerange(mtab, seconds(b(1))/fps,seconds(b(end)/fps));
    baseline.exp_state(:)= "Baseline";
    stim = timerange(mtab,seconds(s(1))/fps,seconds(s(end)/fps));
    stim.exp_state(:) = "Stimulation";
    post = timerange(mtab,seconds(p(1))/fps,seconds(p(end)/fps) - seconds(1/fps));
    post.exp_state(:) = "Post-Stimulation";

    %     segs =  begonia.data_management.multitable.segment_entity(mtab, "exp_state", ["Baseline","Stim","Post"]);
    %     baseline = segs(segs.seg_category ==  "Baseline");
    %     stim =
    %

    %% Segment multitab by behaviour state
    % Get Lomotion state trace from each experimental state
    base_cat = baseline.trace{baseline.category == "locomotion"};
    stim_cat = stim.trace{stim.category == "locomotion"};
    post_cat = post.trace{post.category == "locomotion"};

    % Check present locomotion categories in the locomotion trace (otherwise it will
    % give an error when segmenting if the loc. category is not present)
    b_cats = unique(base_cat);
    s_cats = unique(stim_cat);
    p_cats = unique(post_cat);

    % Segment multitable of each exp. state and save it. WOuld have been
    % better to use segement entity
    base_tab = segment_globally(baseline,base_cat,1/fps,b_cats);
    stim_tab = segment_globally(stim,stim_cat,1/fps,s_cats);
    post_tab = segment_globally(post,post_cat,1/fps,p_cats);

    % Update segmets frames of stimulation and post-stimulaiton tables
    stim_tab.seg_start_f = [stim_tab.seg_start_f] + s(1)-1;
    stim_tab.seg_end_f = [stim_tab.seg_end_f] + s(1)-1;
    post_tab.seg_start_f = [post_tab.seg_start_f] + p(1)-1;
    post_tab.seg_end_f = [post_tab.seg_end_f] + p(1)-1;

    mtab_seg = [base_tab;stim_tab;post_tab];

    % Add experimetnal category (noIVM,IVM,postIVM)
    mtab_seg.exp_category(:) = exp_cat;

    % Add virus injeciton (Glyr or noGlyR)
    try
        vir = ts.load_var('virus');
        mtab_seg.virus(:) = vir;
    catch
        warning("no virus category assigned to " + ts.name)
        mtab_seg.virus(:) = nan;
    end

    ts.save_var("multitab_segmented",mtab_seg)
end
end