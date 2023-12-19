function save_plot(ts,path,fig,plot_type,chan)

genotypes = ["Bl6","IP3R2","AQP4-1"];
ts_path = ts.path;
% s = regexp(ts.path,genotypes);
% gen_idx = find(~cellfun(@ismepty,ans));
s = split(ts_path,"/");
gen_idx = ismember(genotypes,s);
genotype = genotypes(gen_idx);
subfolder = fullfile(path,genotype);
if ~isfolder(subfolder), mkdir(subfolder), end
ts_path = fullfile(subfolder,ts.name);
if ~isfolder(ts_path), mkdir(ts_path), end
fig_name = plot_type;
if plot_type == "roa_3d"
    fig_name = fig_name + "_" + chan;
end
outpng = fullfile(ts_path,fig_name);
print(fig,outpng,'-r300','-dpng')
end