function get_max_stim(tss,do_save)
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
        stim = rr(:,30:60);
        max_dff = max(stim,[],2);
        tab = table(max_dff');
        m{j} = max_dff;
        x{j} = ones(length(max_dff),1) * j;
        
        %plot(ones(length(max_dff)), max_dff,'o')
        
        tab = splitvars(tab,'Var1');
        in_title = nc(j);
        t = string(cats(i)) + "_ " + in_title + " max_dff";
        if do_save
            p = [path,'/tabs'];
            outab = fullfile(p,t);
            writetable(tab,outab,'FileType','spreadsheet')
        end
    end
    data = cell2mat(m');
    nx = cell2mat(x');
    fig = figure;
    boxplot(data,nx)
    ylim([0 8])
    k = string(c) + " max dff";
    title(k)
    set(gca,'XTickLabel',nc)
    if do_save
        outpng = fullfile(path,k);
        print(fig, outpng, '-r300', '-depsc');
    end
    delete(fig)
    % ylim([0 8])
end
disp("Done!")
end
