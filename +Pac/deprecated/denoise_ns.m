function denoise_ns(tss,level)

if nargin < 2, level = 9; end

for ts = tss

    begonia.logging.log(1,"Denoising ns rois of " + ts.name)

    tab = ts.load_var('roi_signals_dff_subtracted');
    dff = vertcat(tab.signal_subtracted_dff{:});
    ns_idx = all(~isnan(dff'))';

    ns_dff = dff(ns_idx,:);

    denoised = zeros(size(ns_dff,1),length(ns_dff));
    for i = 1:size(ns_dff,1)
        denoised(i,:) = denoise_it(ns_dff(i,:),level);
    end

    tab.signal_subtracted_dff(ns_idx) = num2cell(denoised,2);
    tab.Properties.VariableNames(2) = "signal_denoised_dff";

    ts.save_var('denoised_ns_dff',tab)
end
end


function d = denoise_it(data,level)
levelForReconstruction = false(11,1);
levelForReconstruction(1:level) = true;
levelForReconstruction = flip(levelForReconstruction);

% levelForReconstruction = [false,false,true,true,true,true,true,true,true,true,true];

% Perform the decomposition using modwt
wt = modwt(data,'sym4',10);

% Construct MRA matrix using modwtmra
mra = modwtmra(wt,'sym4');

% Sum down the rows of the selected multiresolution signals
d = sum(mra(levelForReconstruction,:),1);
end