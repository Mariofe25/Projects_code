function plot_channel_rpa(tss,do_save)
path = '/Users/mariofernandez/Downloads/jarand-copy/analysis/channel_traces/rpa';
if nargin < 2, do_save = true;end
if nargin < 1 || isempty(tss)
    tss = begonia.scantype.find_scans(path);
end
idx = tss.has_var('stabilized');
tss = tss(idx);
tags = tss.load_var("tags");
tags = categorical(tags);
cats = unique(tags);
colors = rand(6,3);
for i = 1:length(cats)
    c = cats(i);
    tss_cat = tss(tags == c);
    comp = tss_cat.load_var('compartment_signal');
    compartments = vertcat(comp{:});
    cc = [string(compartments.compartment),compartments.channel];
    nc = unique(cc,"rows");
    
    for j = 1:length(nc)
        comp_idx = compartments.compartment == nc(j);
        channel_idx = compartments.channel == double(nc(j,2));
        rr =  compartments.active_fraction(comp_idx & channel_idx);
        rr = vertcat(rr{:});
        fig = figure;
        ncx.stdshade(rr,0.3,colors(j,:));
        in_title = nc(j);
        if nc(j) == "FOV" && double(nc(j,2)) == 1
            in_title = in_title + " neurons";
            tab = table(rr','VariableNames',"Neurons_CH");
        elseif nc(j) == "FOV" && double(nc(j,2)) == 2
            in_title = in_title + " astrocytes";
            tab = table(rr','VariableNames',"Astrocytes_CH");
        end
        
        t = string(cats(i)) + "_ " + in_title;
        
        if do_save && nc(j) == "FOV"
            p = [path,'/tabs'];
            outab = fullfile(p,t);
            begonia.path.make_dirs(outab)
            writetable(tab,outab,'FileType','spreadsheet')
        end
        
        title(t)
        ylim([0 1])
        xlabel('Time')
        ylabel('Active fraction')
        if do_save
            outpng = fullfile(path,t);
            begonia.path.make_dirs(outpng)
            print(fig, outpng, '-r300', '-depsc','-painters');
        end
        delete(fig)
    end
end
disp("Done!")
end
