%% plot splatter plot & rpa heatmap  and save them

% load tseries
tss = load('/Volumes/Xiaoyi2/4mt/mt.mat');
tss = tss.dlocs;

% Create plot folder
plots_folder = '/Volumes/Xiaoyi2/4mt/Plots';

if ~isfolder(plots_folder)
    mkdir(plots_folder)
end


% Plot splatter & rpa
err_cause = cell(1,2);
n = 0;
for ts = tss
    %% RPA
    try
        p = begonia.processing.rpa.plot_qa_rpa (ts);
        save_plot(ts,plots_folder,p,"rpa") 
        delete(p)
        %% Splatter
        def_conf = struct();
        
        def_conf.start_f = 1;
        def_conf.end_f = ts.frame_count;
        def_conf.ds_x = 5;
        def_conf.ds_y = 5;
        def_conf.ds_z = 50;
        
        c = ts.load_var("splatter_config", def_conf);
        
        % downsample and plot each channel:
        for chan_idx = 1:ts.channels
            chan = "ch" + chan_idx;
            mask_var = "roa_mask_" + chan;
            if ~ts.has_var(mask_var); continue; end
            
            mask = ts.load_var(mask_var);
            x_range = 1:c.ds_x:ts.img_dim(1);
            y_range = 1:c.ds_y:ts.img_dim(2);
            z_range = c.start_f:c.ds_z:c.end_f;
            
            mask_ds = mask(x_range, y_range, z_range);
            f = begonia.processing.roa.plot_roa_3d(...
                mask_ds, ...
                ts.dx * c.ds_x, ...
                ts.dy * c.ds_y, ...
                ts.dt * c.ds_z);
            
            ax = f.CurrentAxes;
            title(ax, ts.name + " / " + upper(chan))
            
            save_plot(ts,plots_folder,f,"roa_3d",chan)
            delete(f)
        end
    catch err
        err_cause{1+n,1} = ts.name;
        err_cause{1+n,2} = err.message;
        n = n + 1;
    end
end


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
