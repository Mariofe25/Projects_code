function  cat_locomotion = categorize_locomotion_old (trials)

for trial = trials    
    loc_class = trial.load_var('locomotion_classification');
    cats = categorical({'Still','Run','Transition_still/run','Transition_still/run_1'...
        'Transition_still/run_2','Transition_run/still','Transition_run/still_1'...
        'Transition_run/still_2'});
    var_names = loc_class.Properties.VariableNames;
    loc_vars = logical(loc_class.Variables);
    loc_tab = table(repmat(categorical("other"),size(loc_class)));
    loc_tab = splitvars(loc_tab,'Var1','NewVariableNames',var_names);
    tab_vars = loc_tab.Variables;   
    for i = 1:length(cats)      
        tab_vars(loc_vars(:,i),i) = cats(i);          
    end
    loc_tab.Variables = tab_vars;
    bb = trial.load_var("running");
    b = logical(bb.Data);
    bin_loc = repmat(categorical("not_running"),length(b),1);
    bin_loc(b) = categorical("Running");
    loc_bin = table(bb.Time,bin_loc,'VariableNames',{'Time','Locomotion'});
    cat_locomotion = [loc_bin,loc_tab];
    trial.save_var('Categorize_locomotion',cat_locomotion)
end