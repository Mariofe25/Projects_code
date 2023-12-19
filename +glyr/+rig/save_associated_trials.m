function save_associated_trials(tss,ts_rig_map)
% save asssociated trials in tss metadata to ease access at a later point
import begonia.logging.log

log(1,'Saving associated trials')
for  ts = tss

trial = ts_rig_map(ts.name);

if isempty(trial)
    warning(ts.name + ": no associated trial found")
    continue
end

ts.save_var("associated_trial",trial.path)

end
log(1,'Done!')
end