%% Get Catalog and Aligned Tseries

% Connect to catalog
GlyR = yucca.datacat.DataCat()
GlyR.connect()
% Find Airpuff entries
air_puff = GlyR.get_by_fuzzyname('airpuff','aligned','01302020');
% Find Airpuff aligned tseries
tss = GlyR.get_data(air_puff)

%% Find associated behaviour 
 trials = [air_puff.overlaping_in_time];
 has_trials = arrayfun(@(t) t.type == "Recording rig output", trials);
 trials = trials(has_trials);
 clear has_trials

 %% Get traces (tseries with ROI array)
 
 
 

