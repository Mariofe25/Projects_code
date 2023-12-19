[no_tr,tr] = glyr.wall_behaviour(tss) %tss

[fov,~,c] = unique(tr.mouse,'stable');
times = double(accumarray(c,1));
fov = categorical(fov);
mtr = table(fov,times);


[fov,~,d] = unique(no_tr.mouse,'stable');
times = double(accumarray(d,1));
fov = categorical(fov);
mntr = table(fov,times);

no_fov_idx = ~ismember(mntr.fov,mtr.fov);

fov = categorical(mntr.fov(no_fov_idx));
times = zeros(height(fov),1);
no_fov  = table(fov,times);

mtr = [mtr;no_fov];

mtr.fov = string(mtr.fov);
mntr.fov = string(mntr.fov);
mtr = sortrows(mtr,'fov');
mntr = sortrows(mntr,'fov');
mtr.fov = categorical(mtr.fov);
mntr.fov = categorical(mntr.fov);

tab = join(mtr,mntr,"Keys","fov");
tab.Properties.VariableNames = {'fov','open_loop_trials','close_loop_trials'};

path = '/Volumes/GlyR/GlyR project/Plots/Trial_Classiffication';
filename = fullfile(path,'tab');
begonia.path.make_dirs(filename);
writetable(tab,filename,'FileType','spreadsheet')

fig = figure;
bar(mntr.fov,[mntr.times';mtr.times'],'grouped')
title('Trial classification')
xlabel('Mouse')
ylabel('Trials')
legend('close-loop','open-loop')
filename = fullfile(path,'trial_class');
begonia.path.make_dirs(filename);

print(fig,filename,'-r300', '-dpng');