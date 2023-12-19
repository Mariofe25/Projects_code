function mtab = get_event_freq(mtab)
% Calculate the roi  event frequency in each behaviour state and
% experimental state and add it as a new mtab variable. It also adds number
% of events

state_secs = mtab.total_sec;
events = mtab.events;
n_events = cellfun(@length,events);

mtab.n_events = n_events;
mtab.events_sec = n_events./state_secs;

end