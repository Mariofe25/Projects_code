fig = figure;
key = "AS";
exp_state = "Stimulation";
tab = events(key);
time_bins = string(tab.Properties.VariableNames(8:end));
pup = tab.pupil_onset;
evs = tab{:,8:end};
imagesc(evs)
colorbar
xticks(1:10:width(tab))
xticklabels(time_bins(xticks))
hold on

% mark transition
xline(9,'LineWidth',2,"Color",'r')
xline(13,'LineWidth',2,"Color",'r')



% add pupil onset
% find the loc onset and subtract the tab variables that are not time
z = find(string(tab.Properties.VariableNames) == "0") - 7;

pup(pup > 0) = ceil(pup(pup > 0)*1/dt) + z;
pup(pup < 0) = z - abs(floor(pup(pup < 0)*1/dt));
pup(pup == 0) = z;

no_pup = isnan(pup);

% mark end of locomotion
for i = 1:height(tab)
    xx = find(ismissing(tab{i,8:end}),1);
    line([xx width(tab)],[i i],'LineWidth',8,'Color','k')
    
    % add pupil onset
    if ~isnan(pup(i))
        line([pup(i) pup(i)],[i-0.5 i+0.5],'LineWidth',4,'Color','w')
    else
        % mark transitions where no pupil onset could be localized
        line([width(tab)-7 width(tab)-7],[i-0.5 i+0.5],'LineWidth',w,'Color','m')
    end
end

xlabel("Time (sec)")
ylabel("n trans")
title(key + " Events onset during transition to locomotion in " + ...
    exp_state + ".White bars = pupil onset")
