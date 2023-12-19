function  cat_locomotion = categorize_locomotion(trials)
for trial = trials
    loc_class = trial.load_var('locomotion_classification');
    cats = categorical({'Still','Run','Transition_still/run_1'...
        'Transition_still/run_2','Transition_run/still_1'...
        'Transition_run/still_2'});
    idx = [1,2,4,5,7,8];
    cat_locomotion = repmat(categorical(""),height(loc_class),1);
    for i = 1:length(idx)
       in = logical(loc_class.(idx(i)));
       cat_locomotion(in) = cats(i);
    end
    
    if all(isundefined(cat_locomotion(end-39:end))) && all(isundefined(cat_locomotion(1:40)))
        cat_locomotion(1:40) = categorical("Start");
        cat_locomotion(end-39:end) = categorical("End");
    end

%     bb = trial.load_var("running");
%     b = logical(bb.Data);
%     bin_loc = repmat(categorical("not_running"),length(b),1);
%     bin_loc(b) = categorical("Running");
%     loc_bin = table(bb.Time,bin_loc,'VariableNames',{'Time','Locomotion'});
%     cat_locomotion = [loc_bin,loc_tab];
      trial.save_var('Categorize_locomotion',cat_locomotion)
end
end