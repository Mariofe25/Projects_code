function group_dff_roi_type(tss,do_save)
path = '/Users/mariofernandez/Downloads/jarand-copy';
if nargin < 2, do_save = true;end
if nargin < 1 || isempty(tss)
    tss = begonia.scantype.find_scans(path);
end
idx = tss.has_var('stabilized');
tss = tss(idx);
tags = tss.load_var("tags");
tags = categorical(tags);
cats = unique(tags);
colors = rand(5,3);
for i = 1:length(cats)
    c = cats(i);
    tss_cat = tss(tags == c);
    t = tss_cat.load_var('roi_table');
    t = vertcat(t{:});
    type = t.type;
    comp = tss_cat.load_var('roi_signals_dff');
    compartments = vertcat(comp{:});
    compartments.type = type;
    nc = unique(type);
    for j = 1:length(nc)
        rr =  compartments.signal_dff(compartments.type == nc(j));
        rr = vertcat(rr{:});
        tab = table(rr');
        tab = splitvars(tab,'Var1');
        fig = figure;
        ncx.stdshade(rr,0.3,colors(j,:));
        in_title = nc(j);
        if nc(j) == "FOV" && double(nc(j,2)) == 1
            in_title = in_title + " neurons";
        elseif nc(j) == "FOV" && double(nc(j,2)) == 2
            in_title = in_title + " astrocytes";
        end
        t = "dff " + string(cats(i)) + "_ " + in_title;
        title(t)
        ylim([0 5])
        xlabel('Time')
        ylabel('dff')
        if do_save
            p = [path,'/tabs'];
            outab = fullfile(p,t);
            writetable(tab,outab,'FileType','spreadsheet')
            outpng = fullfile(path,t);
            print(fig, outpng, '-r300', '-depsc');
        end
        delete(fig)
    end
end
disp("Done!")
end
