behav = ["Still","Motion","Run"];
exp_state = ["Baseline", "Stimulation"];
drug = string(unique(tss.load_var('drug')));
path = "/Volumes/GlyR/GlyR project/Plots/Pupil_size/" + drug;
fig = figure;
hold on
for i = 1:length(behav)
    [pups,btsp] = glyr.rig.pupil.raw_pupil_boottrap(tss,behav(i),0,1);
end


hh = flipud(findobj(fig,'type',"Histogram"));
names = exp_state' + "-" + behav;
legend(hh,names(:));


filename = fullfile(path,"Pupil_Size_dristeibution_btstrp_" + drug);
begonia.path.make_dirs(filename)
print(fig,filename,'-r300', '-depsc')




