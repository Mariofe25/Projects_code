% Select tseries by behavior state during the transition to stimulation.
% 1. Running 
% 2. Still

% load noIVM tseries
glyr.processing.load_noIVM_tss;

% Take al transitions, independent of behaviour state during the
% transitions
[trs,runtab] = glyr.get_trans2stim_data(tss,"All",2,5);
glyr.trans2stim(trs,runtab,"All",0,1,1)

% Filter tsereis for running periods
[trs,runtab] = glyr.get_trans2stim_data(tss,"Run",2,5);
glyr.trans2stim(trs,runtab,"Run",0,1,1)

% Filter tsereis for still periods
[trs,stilltab] = glyr.get_trans2stim_data(tss,"Still",2,4);
glyr.trans2stim(trs,stilltab,"Still",0,1,1)