function summary_latency(tss,do_save, thres)
if nargin < 3, thres = "median";end
if nargin < 2, do_save = true;end
tag = tss.load_var('tags');
tag = string(unique(tag));
tab_dirs = dir( "/Users/mariofernandez/Downloads/jarand-copy/analysis/latency/" + thres + "/tabs");
tab_names = string({tab_dirs.name})';
tab_folders = string({tab_dirs.folder})';
compartments = ["AE","AP","AS"];

for t = tag
    tabs_idx = contains(tab_names,t);
    tabs_idx = find(tabs_idx);
    tab_path = arrayfun(@(x) fullfile(tab_folders(x),tab_names(x)),tabs_idx,"UniformOutput",false);
    tab_path = cellfun(@sort,tab_path);
    tabs = cellfun(@readtable,tab_path,"UniformOutput",false)';
    
    tab_vars = string(tabs{1}.Properties.VariableNames);
    
    for tv = tab_vars
        if tv == "threshold" || tv == "max_peak_value"
            continue
        end
        
        % rois with response
%         n_rois = cellfun(@height,tabs);
%         yes_rois = cellfun(@(s) sum(~isnan(s.time_to_onset)),tabs);
        
        % mean/std vars
        var_mean = cellfun(@(x) mean(x.(tv),"omitnan"),tabs);
        var_std = cellfun(@(x) std(x.(tv),"omitnan"),tabs);
        
        % plots
        fig = figure;
        bar(var_mean)
        tit =  sprintf(string(t) + '\n' + " Ca2+ kinetics by compartment");
        title(tit)
        ylabel(tv + " (sec)");
        hold on
        errorbar(1:size(var_std,2),var_mean,[],var_std,"LineStyle","none","Color","k")
        ylim([0 20])
        xticklabels(compartments)
        hold off
        if do_save
            path = "/Users/mariofernandez/Downloads/jarand-copy/analysis/latency/" + thres + "/sumary_plots";
            fname = fullfile(path,t);
             if~isfolder(fname),mkdir(fname),end
            fname2 = t + "_" + tv;
            outpng = fullfile(fname,fname2);
            print(fig, outpng, '-r300', '-dpng');
        end     
        delete(fig)
    end
    
end
end